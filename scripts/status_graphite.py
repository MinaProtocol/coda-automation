#!/usr/bin/python3
# simple status counters in graphite

import json
import socket
import graphyte
import subprocess

def cli(cmd='uname'):
    result = subprocess.run(cmd.split(), stdout=subprocess.PIPE)
    return(result.stdout.decode('utf-8').strip())

# Load sensitive config
try:
    with open('/etc/testnet_config.json') as config_file:
        config = json.load(config_file)
        testnet = config['testnet']
except IOError as error:
    print('Error opening secrets config:', error)
    sys.exit(1)

hostname = socket.gethostname().replace('.','_')
status_metrics   = graphyte.Sender('localhost', prefix='testnet.%s.status.byhost.%s'   % (testnet, hostname))

status = json.loads(cli('coda client status -json'))

for stat in ['uptime_secs', 'blockchain_length']:
    status_metrics.send(stat,int(status[stat]))

status_metrics.send('peer_count',int(len(status['peers'])))
