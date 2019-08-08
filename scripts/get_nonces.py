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


keys = json.loads(cli('coda advanced get-public-keys -j'))[40:]
keys_with_balances = json.loads(cli('coda advanced get-public-keys -w -j'))['accounts']
balances={}
for item in keys_with_balances:
    for key in item:
        balances[key] = item[key]

pool = Pool(processes=4)
nonces = pool.map(get_nonce, keys)
noncesum=0

for mydict in nonces:
    if mydict['nonce'] == '0':
        continue
    else:
        noncesum += int(mydict['nonce'])
        #print(mydict)
        gmetrics = graphyte.Sender('localhost', prefix='testnet.%s.stats.nonce_bykey.%s' % (testnet, mydict['key'][:10]), log_sends=True)
        gmetrics.send('nonce_count',int(mydict['nonce']))

        gmetrics = graphyte.Sender('localhost', prefix='testnet.%s.stats.balance_bykey.%s' % (testnet, mydict['key'][:10]), log_sends=True)
        gmetrics.send('balance', int(balances[mydict['key']]))

print('Total:', noncesum)


gmetrics = graphyte.Sender('localhost', prefix='testnet.%s.stats' % testnet, log_sends=True)
gmetrics.send('nonce_sum', noncesum)
