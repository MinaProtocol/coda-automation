import click
import json
import sys
import logging
import collections
from datetime import datetime, timedelta
from google.cloud import logging as glogging
import os
import sys
import json
import click
import subprocess
import requests
import time
import logging
import random
import backoff 

from concurrent.futures import ThreadPoolExecutor

from kubernetes import client, config
from kubernetes.stream import stream

import CodaClient 

from kubernetes import client, config
from kubernetes.stream import stream
from graphviz import Digraph

from best_tip_trie import BestTipTrie
from logs import fetch_logs
import time 

import networkx as nx
import matplotlib.pyplot as plt


import sys
sys.setrecursionlimit(1500)

@click.group()
@click.option('--namespace',
              default="hangry-lobster",
              help='Namespace to Query.')
@click.option('--hours-ago',
              default="1",
              help='Consider logs generated between <hours-ago> and now.')
@click.option('--max-entries',
              default=1000,
              help='Maximum number of log entries to load.')
@click.option('--cache-logs/--no-cache',
              default=False,
              help='Consider logs generated between <hours-ago> and now.')
@click.option('--cache-file',
                default="./cached-logs.json",
                help="File location to write download logs to")
@click.option('--in-file',
                default=None,
                help="Load logs from this file instead of querying Stackdriver")
@click.pass_context
def cli(ctx, namespace, hours_ago, cache_logs, cache_file, in_file, max_entries):
    ctx.ensure_object(dict)

    ctx.obj['namespace'] = namespace
    ctx.obj['hours_ago'] = hours_ago
    ctx.obj['cache_logs'] = cache_logs
    ctx.obj['cache_file'] = cache_file
    ctx.obj['in_file'] = in_file
    ctx.obj['max_entries'] = max_entries


@cli.command()
@click.pass_context
def visualize_gossip_net(ctx):
    # Python Logging Config
    logging.basicConfig(stream=sys.stdout, level=logging.INFO)
    logger = logging.getLogger()

    if ctx.obj["cache_logs"]:
        outfile = open(ctx.obj["cache_file"], "w")

    if ctx.obj["in_file"] == None:
        RECEIVED_BLOCK_FILTER = ' "Received a block $block from $sender"'
        log_iterator = fetch_logs(namespace=ctx.obj["namespace"], hours_ago=ctx.obj["hours_ago"], log_filter=RECEIVED_BLOCK_FILTER)
    else:
        fd = open(ctx.obj["in_file"], "r")
        log_iterator = map(lambda x: json.loads(x), fd.readlines())

    network_graph = nx.Graph()

    nBlocks = 0
    for entry in log_iterator:  # API call(s)
        if ctx.obj["cache_logs"] and ctx.obj["in_file"] == None:
            outfile.write(json.dumps(entry, default=str) + "\n")
        json_payload = entry[-1]
        labels = entry[1]
        metadata = json_payload["metadata"]
        sender = metadata["sender"]["Remote"]
        receiver = {
            "peer_id": metadata["peer_id"],
            "host": metadata["host"]
        }
        state_hash = metadata["state_hash"]
        #print(json.dumps(metadata,indent=1))
        
        # if we haven't seen this sender before
        if sender["peer_id"] not in network_graph:
            network_graph.add_node(sender["peer_id"])
        # if we haven't seen this receiver before
        if receiver["peer_id"] not in network_graph:
            network_graph.add_node(receiver["peer_id"])
        # if the sender has sent a node to the receiver before
        if receiver["peer_id"] in network_graph[sender["peer_id"]]:
            # increase the edge weight
            print(f'increasing weight: {network_graph[sender["peer_id"]][receiver["peer_id"]]["weight"]}')
            network_graph[sender["peer_id"]][receiver["peer_id"]]["weight"] += 1
        else:
            # else, just create an edge of width=1
            network_graph.add_edge(sender["peer_id"], receiver["peer_id"], weight=1)




        nBlocks += 1
        if ctx.obj["in_file"] == None:
            time.sleep(.04)
        if nBlocks % 100 == 0:
            logger.info(f"Processing {nBlocks}")
        if nBlocks == ctx.obj["max_entries"]:
            break

    edges = network_graph.edges()
    edgelist = []
    for u,v in edges:
        if network_graph[u][v]["weight"] > 2:
            edgelist.append((u,v))
    #colors = [G[u][v]['color'] for u,v in edges]
    #print (edgelist)
    weights = [network_graph[u][v]['weight'] for u,v in list(edgelist)]
    degree = network_graph.degree()

    print(degree)

    nx.draw_shell(network_graph, width=weights, edgelist=edgelist)
    plt.show()





@cli.command()
@click.pass_context
@click.option('--count-best-tips/--no-best-tips',
              default=False,
              help='Consider best tips of each node when computing graph.')
@click.option('--remote-graphql-port', default=3085, help='Remote GraphQL Port to Query.')
def visualize_blockchain(ctx, count_best_tips, remote_graphql_port):
    # Python Logging Config
    logging.basicConfig(stream=sys.stdout, level=logging.INFO)
    logger = logging.getLogger()

    if ctx.obj["cache_logs"]:
        outfile = open(ctx.obj["cache_file"], "w")

    if ctx.obj["in_file"] == None:
        REBROADCAST_FILTER = ' "Rebroadcasting $state_hash"'
        log_iterator = fetch_logs(namespace=ctx.obj["namespace"], hours_ago=ctx.obj["hours_ago"], log_filter=REBROADCAST_FILTER)
    else: 
        fd = open(ctx.obj["in_file"], "r")
        log_iterator = map(lambda x: json.loads(x), fd.readlines())

    the_blockchain = BestTipTrie()

    nBlocks = 0
    for entry in log_iterator:  # API call(s)
        if ctx.obj["cache_logs"] and ctx.obj["in_file"] == None:
            outfile.write(json.dumps(entry, default=str) + "\n")

        #print(json.dumps(entry, indent=2, default=str))

        block = entry[-1]["metadata"]
        labels = entry[1]
        state_hash = block["state_hash"]
        parent_hash = block["external_transition"]["protocol_state"]["previous_state_hash"]

        logger.debug(json.dumps(block, indent=2, default=str))
        nBlocks += 1

        the_blockchain.insertLink(child=state_hash, parent=parent_hash, value=labels["k8s-pod/app"])
        if ctx.obj["in_file"] == None:
            time.sleep(.03)
        if nBlocks % 100 == 0:
            logger.info(f"Processing {nBlocks}")
        if nBlocks == ctx.obj["max_entries"]:
            break

    logger.info("{} Blocks During the inspected timespan.".format(nBlocks))
    
    if count_best_tips:
        print("Loading Best Tips...")
        config.load_kube_config()

        # Load Best Tips
        v1 = client.CoreV1Api()
        pods = v1.list_namespaced_pod(namespace)
        items = pods.items
        random.shuffle(items)
        items = items[:50]
        def process_pod(args):
            (i, pod) = args
            if pod.metadata.namespace == namespace and 'block-producer' in pod.metadata.name:
                logger.info("Processing {}".format(pod.metadata.name))
                # Set up Port Forward
                logger.debug("Setting up Port Forward")
                
                @backoff.on_exception(backoff.expo,
                                (requests.exceptions.Timeout,
                                requests.exceptions.ConnectionError),
                                max_tries=2)
                def doit():
                    local_port = remote_graphql_port + i + 1
                    command = "kubectl port-forward --namespace {} {} {}:{}".format(pod.metadata.namespace, pod.metadata.name, local_port, remote_graphql_port)
                    logger.debug("Running Bash Command: {}".format(command))
                    proc = subprocess.Popen(["bash", "-c", command],
                                            stdout=subprocess.PIPE,
                                            stderr=subprocess.STDOUT)
                    
                    time.sleep(5)

                    try: 
                        return get_best_chain(local_port)
                    finally:
                        terminate_process(proc)
                    
                    try:
                        result = doit()
                    except requests.exceptions.ConnectionError:
                        logging.error("Error fetching chain for {}".format(pod.metadata.name))
                    return

                    if result['data']['bestChain'] == None: 
                        logging.error("No Best Tip for {}".format(pod.metadata.name))
                        return
                    logger.info("Got Response from {}".format(pod.metadata.name))
                    logger.debug("Contents of Response: {}".format(result))

                    chain = list(map(lambda a: a["stateHash"], result['data']['bestChain']))

                    return (chain, pod)
        
        with ThreadPoolExecutor(max_workers=8) as pool:
            for result in pool.map(process_pod, enumerate(items)):
                if result:
                    #print(result)
                    chain, pod = result
                    the_blockchain.insert(chain, pod.metadata.name[:-16])

    # Render It!

    items = list(([hash[-8:] for hash in key], node.value) for (key, node) in the_blockchain.items())
    forks = list((key, node.children) for (key, node) in the_blockchain.forks())
    prefix = the_blockchain.prefix()
    trie_root = the_blockchain.root

    graph = Digraph(comment='The Round Table', format='png', strict=True)
    # Create graph root
    graph.node("root", "root", color="black")
    graph.edge_attr.update(dir="back")

    render_fork(graph, trie_root)
    #Connect fork root to graph root
    graph.view()


        

def render_fork(graph, root):
    from colour import Color
    blue = Color("white")
    colors = list(blue.range_to(Color("blue"),200))

    if len(root.labels) > 0:
        for label in root.labels:
            graph.node(label, label, color="blue")
            graph.edge(label, root.hash, color="blue")
        color = "blue"
    if root.hash == None:
        root.hash = "root"
    elif "\t"+root.hash not in graph.body:
        # print(colors[len(root.value)].hex_l)
        #print (len(root.value))
        try: 
            graph.node(root.hash, root.hash[-8:], color=colors[len(root.value)].hex_l, shape='ellipse', style='filled')
        except IndexError:
            graph.node(root.hash, root.hash[-8:], color=colors[-1].hex_l, shape='ellipse', style='filled')
    for child in root.children.values():
        try:
            graph.node(child.hash, child.hash[-8:], color=colors[len(child.value)].hex_l, shape='ellipse', style='filled')
        except IndexError: 
            graph.node(root.hash, root.hash[-8:], color=colors[-1].hex_l, shape='ellipse', style='filled')
        graph.edge(root.hash, child.hash)
        render_fork(graph, child)

class CustomError(Exception):     
  pass

@backoff.on_exception(backoff.expo,
                      (requests.exceptions.Timeout,
                      requests.exceptions.ConnectionError),
                      max_tries=3)
def get_best_chain(port):
    coda = CodaClient.Client (graphql_host="localhost", graphql_port=port)
    result = coda._send_query (query="query bestChainQuery { bestChain { stateHash } }")
    return result


def terminate_process(proc):
    proc.terminate()
    try:
        outs, _ = proc.communicate(timeout=0.2)
    #print('== subprocess exited with rc =', proc.returncode)
    #print(outs.decode('utf-8'))
    except subprocess.TimeoutExpired:
        logger.error('subprocess did not terminate in time')


if __name__ == "__main__":
    cli(obj={})