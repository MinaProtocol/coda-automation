#! /usr/bin/env python3

import os
import sys
import time
import codalib
import random
import logging

logFormatter = '%(asctime)s - %(message)s'
logging.basicConfig(format=logFormatter, level=logging.DEBUG)
logger = logging.getLogger(__name__)


order_file = '/etc/coda-proposer_order'
if os.path.isfile(order_file):
    with open(order_file) as f:
        order = f.read()
    big_key = '%s/testkeys/high%s' % (os.getcwd(), order)
else:
    big_key = '%s/testkeys/high0' % (os.getcwd())

clientport = codalib.default_port + 1

def single_transaction(use_new_account=False, fee=4, amount=None):
    ### Single transaction to an existing account

    initial_block = codalib.coda_block(port=clientport)
    if initial_block is False:
        return(False)

    last_block = initial_block
    logger.info('-'*80)
    logger.info('Starting Block: %s' % last_block)

    if use_new_account:
        receiver = codalib.coda_create_keys(count=1)
    else:
        receiver = codalib.random_accounts(port=clientport,count=1)

    if amount is None:
        amount = random.randint(20, 90)

    logger.info('Sending %s to %s' % (amount, receiver[0]))
    codalib.coda_send_transaction(big_key, receiver, amount=amount, fee=fee, port=clientport)

    previous_balance = codalib.coda_get_balance(key=receiver[0],port=clientport)
    expected_balance = previous_balance + amount

    logger.info('Initial Balance: %s - Expected Balance: %s' % (previous_balance, expected_balance))

    balance = 0
    max_blocks = 8
    start_time = time.time()

    while True:
        time.sleep(2)
        current_block = codalib.coda_block(port=clientport)
        if current_block is False:
            return(False)

        if last_block < current_block:
            logger.info('Current Block: %s -- Last Block: %s' % (current_block, last_block))
            last_block = current_block

        if current_block > initial_block + max_blocks:
            logger.info('ERROR: Transaction failed. %s blocks passed' % max_blocks)
            #sys.exit(1)
            break

        balance = codalib.coda_get_balance(key=receiver[0],port=clientport)
        if balance == expected_balance:
            logger.info('Found Exact Match: %s' % balance)
            break
        elif balance > expected_balance:
            logger.info('Found Match > Expected: %s' % balance)
            break

    elapsed_time = time.time() - start_time
    logger.info(time.strftime("Time Elapsed: %H:%M:%S", time.gmtime(elapsed_time)))
    logger.info('Sleeping...')
    time.sleep(2)


if __name__ == "__main__":
    os.environ['CODA_PRIVKEY_PASS'] = 'testnet'

    count=1
    while(True):
        print('-'*80)
        if (count%5==0):
            single_transaction(fee=4, use_new_account=True)
        else:
            single_transaction(fee=4)
        count += 1

    # Test multiple transactions to many new accounts
    #codalib.coda_send_batch_transactions(big_key,
    #                                     codalib.coda_create_keys(count=4))
