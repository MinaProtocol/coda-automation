#!/usr/bin/python3

import fileinput
import requests
import json
import sys
import graphyte
from collections import Counter


def keymap():
    key_to_user = {}
    # Source file https://raw.githubusercontent.com/CodaProtocol/coda/8b1e39a1657ae606f3ca4d10ddf308bf662cce22/src/lib/genesis_ledger/testnet_medium_rare_ledger.ml
    with open("/home/admin/testnet_medium_rare_ledger.ml", "r") as fileHandler:
        for line in fileHandler:
            if '(*' in line:
                commentline = line.replace(
                    '(*', '').replace('*)', '').strip().replace(' ', '_').replace('"', '')
            elif 'tNci' in line:
                keyline = line.replace('"', '').replace(')', '').strip()

                if '#' in commentline:
                    commentline = commentline.split('#')[0]
                    # print(keyline,commentline)
                    key_to_user[keyline] = commentline
    # over rides
    key_to_user['tNciNBsVA4vhxBtZp4bQM3gZsWMr8be6UfmNRRvNqHjRrATsSBLe8XaUUnrT3bMY97kix97S4kBcpNsBiBZdLggsr7XcktkpziPdkFHfDNjALASU46n1Vq64x5rmgswroJ69B6N7Yei4Sz'] = 'Danil_Ushakov'
    return(key_to_user)


def get_blocks():
    myresults = Counter()

    key_to_user = keymap()
    headers = {'Content-type': 'application/json', 'Accept': 'text/plain'}
    query = {"query": "query { blocks(first: 1000) {nodes {creator}}}"}
    r = requests.post('http://localhost:8304/graphql',
                      data=json.dumps(query), headers=headers)
    mydata = json.loads(r.text)['data']['blocks']['nodes']

    for key in mydata:
        if 'creator' in key:
            pubkey = key['creator']
            if pubkey in key_to_user:
                # print(key_to_user[pubkey])
                myresults[key_to_user[pubkey]] += 1
    return(myresults)


if __name__ == "__main__":
    # Load sensitive config
    try:
        with open('/etc/testnet_config.json') as config_file:
            config = json.load(config_file)
            testnet = config['testnet']

    except IOError as error:
        print('Error opening secrets config:', error)
        sys.exit(1)

    results = get_blocks()
    metrics = graphyte.Sender(
        'localhost', prefix='testnet.%s.stats.blocks_byuser' % (testnet))

    for user in results:
        print('data', user, results[user])
        metrics.send(user, int(results[user]))
