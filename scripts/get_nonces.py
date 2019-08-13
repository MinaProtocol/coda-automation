#!/usr/bin/python3

import subprocess
from multiprocessing import Pool
import json
import time
import sys
import graphyte


def cli(cmd='uname'):
    #print(cmd)
    result = subprocess.run(cmd.split(), stdout=subprocess.PIPE)
    return(result.stdout.decode('utf-8').strip())


def get_nonce(key):
    nonce = cli('coda advanced get-nonce -address %s' % (key))
    return({'key': key,
            'nonce': nonce})

# Load sensitive config
try:
    with open('/etc/testnet_config.json') as config_file:
        config = json.load(config_file)
        elastic_url = config['elastic_url']
        testnet = config['testnet']

except IOError as error:
    print('Error opening secrets config:', error)
    sys.exit(1)


dumped_ledger = cli('coda advanced dump-ledger -json')

for line in dumped_ledger.splitlines():
    jline = json.loads(line)
    nonce_sum = 0
    balance_sum = 0
    if 'public_key' in jline:
        nonce_metrics   = graphyte.Sender('localhost', prefix='testnet.%s.stats.nonce_bykey.%s'   % (testnet, jline['public_key'][:12]))
        nonce_metrics.send('nonce_count',int(jline['nonce']))
        nonce_sum += int(jline['nonce'])

        balance_metrics = graphyte.Sender('localhost', prefix='testnet.%s.stats.balance_bykey.%s' % (testnet, jline['public_key'][:12]))
        balance_metrics.send('balance', int(jline['balance']))
        balance_sum += int(jline['balance'])

    sum = graphyte.Sender('localhost', prefix='testnet.%s.stats' % (testnet), log_sends=True)
    sum.send('nonce_sum', nonce_sum)