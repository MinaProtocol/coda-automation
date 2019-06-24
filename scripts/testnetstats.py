#! /usr/bin/env python3

""" pull local stats and post them to elastic """

from datetime import datetime
import logging
import json
from elasticsearch import Elasticsearch
from elasticsearch.exceptions import TransportError
import certifi
import hashlib
from os import environ
import sys
from socket import gethostname
import codalib

def generate_id():
    hostname = gethostname()
    timestamp = datetime.utcnow().timestamp()
    hash_string = "%s-%s" % (hostname, timestamp)
    sha_signature = hashlib.sha256(hash_string.encode()).hexdigest()
    return sha_signature

def create_stats_index(client, index):
    request_body = {
        "settings": {
        },
        'mappings': {
            'stats': {
                'properties': {
                    "block_count":   {'type': 'integer', "index": False},
                    "account_count": {'type': 'integer', "index": False},
                    "peer_count":    {'type': 'integer', "index": False},
                    'peers':         {'index': False, 'type': 'text'},
                }
            }
        }
    }

    # create empty index
    try:
        client.indices.create(index=index, body=request_body)
    except TransportError as e:
        # ignore already existing index
        if e.error == "resource_already_exists_exception":
            pass
        else:
            raise


if __name__ == "__main__":
    # Load sensitive config
    try:
        with open('/etc/testnet_config.json') as config_file:
            config = json.load(config_file)
            elastic_url = config['elastic_url']
            testnet = config['testnet']
    except IOError as error:
        print('Error opening secrets config:', error)
        sys.exit(1)

    index = 'testnetstats'

    # logger levels
    logging.getLogger('elasticsearch').setLevel(logging.ERROR)
    logging.getLogger('urllib3').setLevel(logging.INFO)

    # Connect to es
    es = Elasticsearch("https://%s" % elastic_url,
                        ca_certs=certifi.where())

    # delete old index
    #es.indices.delete(index=index)

    # create/renew index
    create_stats_index(es, index=index)

    # get stats
    stats = codalib.coda_status()

    # Prep data
    body = {
        '@timestamp':    '%s' % datetime.utcnow(),
        'block_count':   stats['block_count'],
        'account_count': stats['num_accounts'],
        'peer_count':    len(stats['peers']),
        'peers':         stats['peers'],
        'hostname':      gethostname(),
        'testnet':       testnet
    }

    print('Posting new data:\n', json.dumps(body, indent=4, sort_keys=True))

    my_id = generate_id()
    result = es.create(index=index, doc_type="stats", id=my_id, body=body)
    print(result)
