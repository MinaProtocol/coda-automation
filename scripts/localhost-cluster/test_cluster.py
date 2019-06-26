import os
import codalib
from collections import defaultdict
import pprint
import json
import numpy as np
import time


pp = pprint.PrettyPrinter(indent=4)


##############################################################################
# Seed

def test_check_seed(host):
    daemon_list = host.process.filter(comm="coda")
    assert len(daemon_list) > 0
    status = codalib.coda_status(port=8301)
    assert status['num_accounts'] > 17, status
    assert status['block_count'] >= 1
    assert status['run_snark_worker'] is False
    pp.pprint(status)


def check_blocks(
        host='',
        previous_block_average=False):
    # Get current block and interval from all
    processes = codalib.coda_processes()

    data = defaultdict(dict)
    block_counts = []
    proposal_intervals = []
    for process in processes:
        status = codalib.coda_status(port=process)
        if 'proposal_interval' in status:
            data[process]['interval'] = status['proposal_interval']/1000
            proposal_intervals.append(status['proposal_interval']/1000)

        if 'block_count' in status:
            data[process]['block_count'] = status['block_count']
            block_counts.append(status['block_count'])
    print(json.dumps(data, sort_keys=True, indent=4))

    # Check that block counts reported aren't too far off
    assert np.var(block_counts) < 0.5
    assert np.var(proposal_intervals) < 0.5

    # Check that blocks are advancing
    if previous_block_average:
        delta = np.average(block_counts) - np.average(previous_block_average)
        assert delta > 0.9
        assert delta < 1.1

    return((block_counts, proposal_intervals))


def check_blocks_over_time(steps=3):
    block_counts = False
    # initial values
    for i in range(steps):
        print('Testing that blocks advance - %s of %s' % (i, steps))
        (block_counts, proposal_intervals) = check_blocks(
            previous_block_average=block_counts)
        snooze = np.average(proposal_intervals)
        print('Sleeping %s seconds' % snooze)
        time.sleep(snooze)


if __name__ == "__main__":
    os.environ['CODA_PRIVKEY_PASS'] = 'testnet'

    check_blocks_over_time()
