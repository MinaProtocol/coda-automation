#!/usr/bin/env python3

import sys
import argparse
import time
import random
import json
import itertools
import numpy as np

from kubernetes import client, config, stream
from discord_webhook import DiscordWebhook

def main():
    parser = argparse.ArgumentParser(description="Make a report for the active network and optionally send to discord")
    parser.add_argument("-n", "--namespace", help="testnet namespace", required=True, type=str, dest="namespace")
    parser.add_argument("-ic", "--incluster", help="if we're running from inside the cluster", required=False, default=False, type=bool, dest="incluster")
    parser.add_argument("-d", "--discord_webhook_url", help="discord webhook url", required=False, type=str, dest="discord_webhook_url")

    # ==========================================

    args = parser.parse_args(sys.argv[1:])

    if args.incluster:
        config.load_incluster_config()
        assert(args.namespace == '')
        with open('/var/run/secrets/kubernetes.io/serviceaccount/namespace', 'r') as f:
            args.namespace = f.read()
    else:
        config.load_kube_config()
    v1 = client.CoreV1Api()

    # ==========================================
    # Crawl network

    pods = v1.list_namespaced_pod(args.namespace, watch=False)

    seed = [ p for p in pods.items if 'seed' in p.metadata.name ][0]
    seed_daemon_container = [ c for c in seed.spec.containers if c.args[0] == 'daemon' ][0]
    seed_vars_dict = [ v.to_dict() for v in seed_daemon_container.env ]
    seed_daemon_port = [ v['value'] for v in seed_vars_dict if v['name'] == 'DAEMON_CLIENT_PORT'][0]

    def exec_on_seed(command):
      exec_command = [
        '/bin/bash',
        '-c',
        command
      ]
      return stream.stream(v1.connect_get_namespaced_pod_exec, seed.metadata.name, args.namespace, command=exec_command, container='seed', stderr=True, stdout=True, stdin=False, tty=False)


    peer_table = {}

    queried_peers = set()
    unqueried_peers = set()

    def add_resp(resp, direct_queried_peers):
      peers = [ json.loads(s) for s in resp.split('\n') if s != '' ]

      key_value_peers = [ ((p['node_ip_addr'], p['node_peer_id']), p) for p in peers ]

      for (k,v) in key_value_peers:
        if k not in peer_table:
          peer_table[k] = v

      queried_peers.update([ p['node_peer_id'] for p in peers ])
      queried_peers.update(direct_queried_peers)
      unqueried_peers.update([ p['peer_id'] for p in list(itertools.chain(*[ p['peers'] for p in peers ])) ])
      unqueried_peers.difference_update(queried_peers)

    resp = exec_on_seed("coda advanced telemetry -daemon-port " + seed_daemon_port + " -daemon-peers")
    add_resp(resp, [])

    while len(unqueried_peers) > 0:
      peer_ids = ','.join(list(unqueried_peers))

      resp = exec_on_seed("coda advanced telemetry -daemon-port " + seed_daemon_port + " -peer-ids " + peer_ids)
      add_resp(resp, list(unqueried_peers))

    seed_status = exec_on_seed("coda client status")

    get_status_value = lambda key: [ s for s in seed_status.split('\n') if key in s ][0].split(':')[1].strip()

    accounts = int(get_status_value('Global number of accounts'))
    blocks = int(get_status_value('Max observed block length'))
    slot_time = get_status_value('Consensus time now')
    epoch, slot = [ int(s.split('=')[1]) for s in slot_time.split(',') ]
    slots_per_epoch = int(get_status_value('Slots per epoch'))
    global_slot = epoch*slots_per_epoch + slot

    peer_numbers = [ len(node['peers']) for node in peer_table.values() ]
    peer_percentiles = [ 0, 5, 25, 50, 95, 100 ]
    peer_percentile_numbers = list(zip(peer_percentiles, np.percentile(peer_numbers, [ 0, 5, 25, 50, 95, 100 ])))

    #import IPython; IPython.embed()
    
    # ==========================================
    # Make report

    report = {
      "namespace": args.namespace,
      "nodes": len(peer_table),
      "epoch": epoch,
      "epoch_slot": slot,
      "global_slot": global_slot,
      "blocks": blocks,
      "block_fill_rate": blocks / global_slot, # TODO add health indicator
      "number_of_peer_percentiles": peer_percentile_numbers, # TODO add health indicator
    }

    # TODO do now
    # * add nodes sync status
    # * add whether nodes are synced to the same block or there's a fork
    # * add who is / is not staking if a csv is passed in

    # TODO do later
    # * link to image of network connectivity, health indicator
    # * transaction count, health indicator
    # * all blocks have a coinbase

    # ==========================================

    # TODO format nicely
    webhook = DiscordWebhook(url=args.discord_webhook_url, content=str(report))
    response = webhook.execute()

if __name__ == "__main__":
    main()

