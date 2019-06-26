#! /usr/bin/env python3

# Mostly deprecated -- use ansible start script

import os
import time
import codalib

proposer_count=5

proposer_private_keys = []
for i in range(proposer_count):
    proposer_private_keys.append('%s/testkeys/high%s' % (os.getcwd(), i))

low_key10 = '%s/testkeys/low10' % (os.getcwd())

# public key for snark workers
snark_key = 'ASjSaik3xeh9v2dI6imveO33Yzo9KuxpH5wluTiOhn+v3JnQJNG9AQAAAQ=='

if __name__ == "__main__":
    os.environ['CODA_PRIVKEY_PASS'] = 'testnet'
    codalib.init_cluster(
        proposers=5,
        proposer_private_keys=proposer_private_keys,
        snark_private_file=proposer_private_keys[0],
        snark_public_key=snark_key,
        snark_workers=0)

    time.sleep(10)
    codalib.cluster_status()
