#!/usr/bin/python3

import subprocess
import json
import sys
import socket
import graphyte


def cli(cmd='uname'):
    result = subprocess.run(cmd.split(), stdout=subprocess.PIPE)
    return(result.stdout.decode('utf-8').strip())


def get_trust():
    trust_raw = cli('coda advanced get-trust-status-all -json')
    try:
        trust = json.loads(trust_raw)
    except json.decoder.JSONDecodeError:
        # silently exit
        sys.exit(1)
    return(trust)


debug = False

# sensitive config
try:
    with open('/etc/testnet_config.json') as config_file:
        config = json.load(config_file)
        elastic_url = config['elastic_url']
        testnet = config['testnet']
except IOError as error:
    testnet = 'UNKNOWN'

myHostName = socket.gethostname().replace('.', '_')

count = 0
for entry in get_trust():
    if 'ip' in entry:
        friendly_ip = entry['ip'].replace('.', '_')

        # skip small values
        if abs(entry['status']['trust']) < 0.001:
            continue
        if debug:
            print(json.dumps(entry, indent=2))

        metrics = graphyte.Sender('localhost', prefix='trust.%s.by_peer.%s.%s' % (
            testnet, myHostName, friendly_ip))
        metrics.send('trust', entry['status']['trust'])
        count += 1
print ('Sent %s trust metrics.' % count)
