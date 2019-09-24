#!/usr/bin/env python3

# Render pdf of peer topology based on 'coda client status'

from graphviz import Digraph
import re
import socket

# input is in the form of "adhoc $ENV 'coda client status'"
input = """"""

dot = Digraph(comment='Peer Diagram')

for line in input.split('\n'):
    if 'ec2' in line:
        data = line.split()
        hostname = data[0]
        print(hostname)
        hostname_short = hostname.replace('.amazonaws.com', '').replace(
            '.compute-1', '').replace('.compute', '')
        nodeip = socket.gethostbyname(hostname)
        dot.node(nodeip, label='o1node\n%s' %
                 hostname_short, color='green', style='filled')

    elif 'Peers' in line:
        data = re.search(r'\((.*?)\)', line).group(1)
        for peer in data.split():
            print(peer)
            (peerip, port) = peer.split(':')
            print(peerip)
            dot.edge(nodeip, peerip)
print(dot.source)
dot.render('peerdot.gv', view=True)
