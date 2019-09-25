#!/usr/bin/python3

from collections import Counter
import subprocess
import json
import time
import sys
import graphyte
import math


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


# See also https://github.com/CodaProtocol/coda/blob/develop/src/lib/consensus/proof_of_stake.ml#L821-L846
def stake_likelyhood(balance=None, total=None, c=1, f=0.5):
    return (2 ** c * (1 - (1 - f) ** (balance/total)))


key_to_stake = Counter()

for row in cli('coda advanced dump-ledger -json').splitlines():
    data = json.loads(row)
    #print(json.dumps(data, indent=4))

    # track stake by key
    if data['delegate'] == data['public_key']:
        # delegated to self
        # print('self')
        key_to_stake[data['public_key']] += data['balance']
    else:
        # delegated to other
        # print('other')
        key_to_stake[data['delegate']] += data['balance']
        key_to_stake[data['public_key']] += 0

    # totals
    key_to_stake['total'] += data['balance']

# sort keys by value
key_to_stake_sorted = sorted(
    key_to_stake.items(), key=lambda x: x[1], reverse=True)

# Print top keys
for (key, value) in key_to_stake_sorted:
    if key == 'total':
        continue
    stake = key_to_stake[key]
    total = key_to_stake['total']
    percent = stake/total*100
    block_chance = stake_likelyhood(balance=stake, total=total)*100
    print("Key: %s... \tStake: %s (%6.3f) %% \tWin: %6.3f %%" %
          (key[:15], stake, percent, block_chance))
