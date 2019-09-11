#!/usr/bin/env python3

import CodaClient
import json
from datetime import datetime
from collections import Counter
import pubkey_to_discord

starttime = datetime(2019, 9, 11, 9, 0)
endtime   = datetime(2019, 9, 11, 10, 0)

coda = CodaClient.Client(graphql_host="localhost", graphql_port="8304")
blocks = coda.get_blocks()

golden_transactions={}
golden_provers={}

all_transactions = Counter()
all_provers = Counter()

for block in blocks['blocks']['nodes']:
    timestamp = int(int(block['protocolState']['blockchainState']['date'])/1000)
    dt = datetime.fromtimestamp(timestamp)

    if dt >= starttime and dt <= endtime:
        transactions = Counter()
        for transaction in block['transactions']['userCommands']:
            transactions[transaction['from']] += 1
        print('TXNS', transactions)
        golden_transactions[timestamp] = transactions
        all_transactions += transactions

        provers = Counter()
        for snarkjob in block['snarkJobs']:
            provers[snarkjob['prover']] += 1
        print ('SNARKS', provers)
        golden_provers[timestamp] = provers
        all_provers += provers

def print_key_counter(mycounter, label='UNKNOWN'):
    print(label,':\t', sum(mycounter.values()))
    for (key, count) in mycounter.most_common():
        if key in pubkey_to_discord.keymap:
            key = pubkey_to_discord.keymap[key]
        print("\t",count,"\t",key[:20])

timestamps = list(golden_transactions.keys())
timestamps.sort()
for timestamp in timestamps:
    print('-'*40)
    print(datetime.fromtimestamp(timestamp))
    print_key_counter(golden_transactions[timestamp], label='TXNs')
    print_key_counter(golden_provers[timestamp], label='SNKs')

print('='*40)
print_key_counter(all_transactions, label='ALL TXNs')
print_key_counter(all_provers, label='ALL SNKs')

