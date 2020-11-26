#!/usr/bin/env python3

# example of running locally
# MAKE_REPORT_DISCORD_WEBHOOK_URL=""
# python3 services/coda-network-services/make_report.py -n $namespace --discord_webhook_url $MAKE_REPORT_DISCORD_WEBHOOK_URL -a "$(cat accounts.csv)"

import sys
import traceback
import argparse
import time
import random
import itertools
import numpy as np
import ast
import json
import csv
from graphviz import Digraph

from kubernetes import client, config, stream
from discord_webhook import DiscordWebhook

namespace = ''
discord_webhook_url = None

def main():

    global discord_webhook_url
    global namespace
    parser = argparse.ArgumentParser(description="Make a report for the active network and optionally send to discord")
    parser.add_argument("-n", "--namespace", help="testnet namespace", required=True, type=str, dest="namespace")
    parser.add_argument("-ic", "--incluster", help="if we're running from inside the cluster", required=False, default=False, type=bool, dest="incluster")
    parser.add_argument("-d", "--discord_webhook_url", help="discord webhook url", required=False, type=str, dest="discord_webhook_url")
    parser.add_argument("-a", "--accounts", help="community accounts csv", required=False, type=str, dest="accounts_csv")

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

    namespace = args.namespace

    if namespace.startswith('integration-test-'):
      return

    discord_webhook_url = args.discord_webhook_url
    if discord_webhook_url is not None:
      discord_webhook_url = discord_webhook_url.strip()

    # ==========================================
    # Crawl network

    pods = v1.list_namespaced_pod(args.namespace, watch=False)

    seed = [ p for p in pods.items if 'seed' in p.metadata.name ][0]
    seed_daemon_container = [ c for c in seed.spec.containers if c.args[0] == 'daemon' ][0]
    seed_vars_dict = [ v.to_dict() for v in seed_daemon_container.env ]
    seed_daemon_port = [ v['value'] for v in seed_vars_dict if v['name'] == 'DAEMON_CLIENT_PORT'][0]

    request_timeout_seconds = 600

    def exec_on_seed(command):
      exec_command = [
        '/bin/bash',
        '-c',
        command
      ]
      return stream.stream(v1.connect_get_namespaced_pod_exec, seed.metadata.name, args.namespace, command=exec_command, container='seed', stderr=True, stdout=True, stdin=False, tty=False, _request_timeout=request_timeout_seconds)


    peer_table = {}

    queried_peers = set()
    unqueried_peers = set()

    telemetry_heartbeat_errors = []
    telemetry_transport_stopped_errors = []
    telemetry_handshake_errors = []
    telemetry_other_errors = []

    def contains_error(resp):
      try:
        resp['error']
        return True
      except KeyError :
        return False

    def no_error(resp):
      return (not (contains_error(resp)))

    def add_resp(resp, direct_queried_peers):
      # we use ast instead of json to handle properties with single quotes instead of double quotes (which the response seems to often contain)
      resps = [ ast.literal_eval(s) for s in resp.split('\n') if s != '' ]

      print ('Received %s telemetry responses'%(str(len(resps))))

      peers = filter(no_error,resps)
      error_resps = filter(contains_error,resps)

      print ('%s responses from peers'%(str(len(list(peers)))))
      print ('%s error responses'%(str(len(list(error_resps)))))

      key_value_peers = [ ((p['node_ip_addr'], p['node_peer_id']), p) for p in peers ]

      for (k,v) in key_value_peers:
        if k not in peer_table:
          peer_table[k] = v

      queried_peers.update([ p['node_peer_id'] for p in peers ])
      queried_peers.update(direct_queried_peers)
      unqueried_peers.update([ p['peer_id'] for p in list(itertools.chain(*[ p['peers'] for p in peers ])) ])
      unqueried_peers.difference_update(queried_peers)

      for e in error_resps:
        error = str(e['error'])
        if 'handshake error' in error:
          telemetry_handshake_errors.append(e)
        elif 'heartbeats' in error:
          telemetry_heartbeat_errors.append(e)
        elif 'transport stopped' in error:
          telemetry_transport_stopped_errors.append(e)
        else:
          telemetry_other_errors.append(e)

    print ('Gathering telemetry from daemon peers')

    resp = exec_on_seed("coda advanced telemetry -daemon-port " + seed_daemon_port + " -daemon-peers" + " -show-errors")
    add_resp(resp, [])

    while len(unqueried_peers) > 0:
      peer_ids = ','.join(list(unqueried_peers))

      print ('Gathering telemetry on %s specified peers'%(str(len(peer_ids))))

      resp = exec_on_seed("coda advanced telemetry -daemon-port " + seed_daemon_port + " -peer-ids " + peer_ids + " -show-errors")
      add_resp(resp, list(unqueried_peers))

    seed_status = exec_on_seed("coda client status")
    if seed_status == '':
      raise Exception("unable to connect to seed node within " + str(request_timeout_seconds) + " seconds" )

    get_status_value = lambda key: [ s for s in seed_status.split('\n') if key in s ][0].split(':')[1].strip()

    accounts = int(get_status_value('Global number of accounts'))
    blocks = int(get_status_value('Max observed block length'))
    slot_time = get_status_value('Consensus time now')
    epoch, slot = [ int(s.split('=')[1]) for s in slot_time.split(',') ]
    slots_per_epoch = int(get_status_value('Slots per epoch'))
    global_slot = epoch*slots_per_epoch + slot

    peer_numbers = [ len(node['peers']) for node in peer_table.values() ]
    peer_percentiles = [ 0, 5, 25, 50, 95, 100 ]

    if len(peer_numbers) > 0:
      peer_percentile_numbers = list(zip(peer_percentiles, np.percentile(peer_numbers, [ 0, 5, 25, 50, 95, 100 ])))
    else:
      peer_percentile_numbers = []

    block_producers = list(itertools.chain(*[ pv['block_producers'] for pv in peer_table.values() ]))

    peer_to_k_block_hashes = { p: pv['k_block_hashes'] for p,pv in  peer_table.items() }

    fork_tree = {}

    for block_hashes in peer_to_k_block_hashes.values():
      parents = block_hashes
      children_or_none = [ [ c ] for c in block_hashes[1:] ] + [ [] ]
      for parent, child_or_none in zip(parents, children_or_none):
        fork_tree.setdefault(parent, { 'children': set(), 'peers': 0 })
        fork_tree[parent]['children'].update(child_or_none)
        fork_tree[parent]['peers'] += 1

    children = list(itertools.chain(*[ v['children'] for v in fork_tree.values() ]))
    roots = set(fork_tree.keys()).difference(children)

    summarized_fork_tree = {}

    def add_to_summarized_tree(parent):
      peers = fork_tree[parent]['peers']
      children = fork_tree[parent]['children']
      intermediate_nodes = 0
      while len(children) == 1 and fork_tree[list(children)[0]]['peers'] == peers:
        children_or_none = fork_tree[list(children)[0]]['children']
        if len(children_or_none) > 0:
          children = fork_tree[list(children)[0]]['children']
          intermediate_nodes += 1
        else:
          break
      summarized_fork_tree[parent] = { 'children': children, 'peers': peers, 'intermediate_nodes': intermediate_nodes }
      for child in children:
        add_to_summarized_tree(child)

    for root in roots:
      add_to_summarized_tree(root)

    def has_forks():
      roots_with_children = [ root for root in roots if len(fork_tree[root]['children']) > 0 ]
      # can be multiple roots because of nodes syncing from genesis; however there shouldn't be multiple roots with children, that would indicate a fork longer than k
      if len(roots_with_children) > 1:
        return True
      if len(roots_with_children) == 0:
        return False
      root = roots_with_children[0]
      tips = [ node for node,values in summarized_fork_tree.items() if len(values['children']) == 0 ]
      tip_parents = [ node for node,values in summarized_fork_tree.items() if len(set(tips).intersection(values['children'])) > 0 ]
      # there can be different tips (since nodes can be 1 slot out of sync). A fork longer than one slot indicates there is a fork going on though, either from malicious behavior or a bug in the protocol. Note as long as the fork is less than k blocks the protocol consensus is safe and the protocol will recover when the attack ends
      if len(tip_parents) > 1:
        return True
      return False

    if args.accounts_csv is None:
      has_participants = False
    else:
      has_participants = len(args.accounts_csv.strip()) > 0

    participants_online = []
    participants_offline = []

    if has_participants:
      rows = []
      reader = csv.reader(args.accounts_csv.strip().split('\n'), delimiter=",")
      for row in reader:
        rows.append(row)

      key_to_discord = { row[1]: row[0] for row in rows[1:] }

      participants_online = [ discord for (key,discord) in key_to_discord.items() if key in block_producers ]
      participants_offline = [ discord for (key,discord) in key_to_discord.items() if key not in block_producers ]
    else:
      key_to_discord = {}

    # ==========================================
    # Make report

    report = {
      "namespace": args.namespace,
      "nodes": len(peer_table),
      "telemetry_handshake_errors": len(telemetry_handshake_errors),
      "telemetry_heartbeat_errors": len(telemetry_heartbeat_errors),
      "telemetry_transport_stopped_errors": len(telemetry_transport_stopped_errors),
      "telemetry_other_errors": len(telemetry_other_errors),
      "epoch": epoch,
      "epoch_slot": slot,
      "global_slot": global_slot,
      "blocks": blocks,
      "block_fill_rate": blocks / global_slot,
      "number_of_peer_percentiles": peer_percentile_numbers, # TODO add health indicator
      "summarized_block_tree": summarized_fork_tree,
      "has_forks": has_forks(),
      "has_participants": has_participants,
      "participants_online": participants_online,
      "participants_offline": participants_offline,
      "peer_table": peer_table,
    }

    #import IPython; IPython.embed()

    # TODO
    # * timing of block receipt with a health indicator
    # * nodes sync statuses
    # * transaction counts with a health indicator
    # * check that all blocks have a coinbase

    # ==========================================

    # TODO
    # display of network connectivity

    def make_block_tree_graph():
      g = Digraph("block_tree", format='png')
      g.attr('node', shape='circle')
      for block in summarized_fork_tree:
        g.node(block, label='block ' + block[-6:] + '\n' + str(summarized_fork_tree[block]['peers']) + ' nodes')
      g.attr('node', shape='rectangle', style='filled', color='lightgrey')
      for block in summarized_fork_tree:
        children = summarized_fork_tree[block]['children']
        intermediate_nodes = summarized_fork_tree[block]['intermediate_nodes']
        if len(children) > 0:
          if intermediate_nodes > 0:
            g.node(block + '_intermediate', label=str(intermediate_nodes) + ' in common blocks')
            g.edge(block, block + '_intermediate')
            for child in children:
              g.edge(block + '_intermediate', child)
          else:
            for child in children:
              g.edge(block, child)
      g.render(view=False)

    make_block_tree_graph()

    copy = [ 'namespace', 'nodes', 'epoch', 'epoch_slot', 'global_slot', 'blocks', 'block_fill_rate', 'has_forks', 'has_participants', "telemetry_handshake_errors", "telemetry_heartbeat_errors", "telemetry_transport_stopped_errors", "telemetry_other_errors" ]
    json_report = {}
    for c in copy:
      json_report[c] = report[c]

    json_report['participants_online'] = len(report['participants_online'])
    json_report['participants_offline'] = len(report['participants_offline'])

    json_report['number_of_peer_percentiles'] = ' | '.join([ str(p) + '%: ' + str(v) for (p,v) in report['number_of_peer_percentiles'] ])

    if json_report['has_forks']:
      json_report['has_forks'] = str(json_report['has_forks']) + ' :warning:'

    if json_report['block_fill_rate'] < .75 - .10:
      json_report['block_fill_rate'] = str(json_report['block_fill_rate']) + ' :warning:'


    formatted_report = json.dumps(json_report, indent=2)

    if discord_webhook_url is not None and len(discord_webhook_url) > 0:
      discord_char_limit = 2000
      if len(formatted_report) > discord_char_limit - 5:
        formatted_report[:discord_char_limit - 5] + '...'

      webhook = DiscordWebhook(url=discord_webhook_url, content=formatted_report)

      with open("block_tree.gv.png", "rb") as f:
        webhook.add_file(file=f.read(), filename='block_tree.gv.png')

      webhook.add_file(file=str(report['participants_online']), filename='particpants_online.txt')
      webhook.add_file(file=str(report['participants_offline']), filename='participants_offline.txt')

      peer_table_dict = { str(k): { 'block_producers': v['block_producers'],
                               'protocol_state_hash': v['protocol_state_hash'],
                               'discord(s)': [ key_to_discord.get(key, '') for key in v['block_producers'] ] } for k,v in report['peer_table'].items() }


      peer_table_str = json.dumps(peer_table_dict, indent=2)

      webhook.add_file(file=peer_table_str, filename='peer_table.txt')

      response = webhook.execute()

if __name__ == "__main__":
  try:
    main()
  except Exception as e:
    exc_type, exc_obj, exc_tb = sys.exc_info()
    trace = traceback.format_exc()
    print(str(namespace) + " exited with error", trace)
    if discord_webhook_url is not None and len(discord_webhook_url) > 0:
      webhook = DiscordWebhook(url=discord_webhook_url, content=str(namespace) + " exited with error: " + str(trace))
      response = webhook.execute()
