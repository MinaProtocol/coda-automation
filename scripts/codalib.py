# Python pseudo-library for coda hooks
from __future__ import print_function
import time
import datetime
import json
import sexpdata
import os
import sys
import glob
import shutil
import random
import uuid
import psutil
from subprocess import Popen, PIPE
from multiprocessing import Pool
from collections import Counter
from collections import defaultdict

import logging

logger = logging.getLogger()
handler = logging.StreamHandler()
formatter = logging.Formatter(
        '%(asctime)s %(name)-12s %(levelname)-8s %(message)s')
handler.setFormatter(formatter)
logger.addHandler(handler)
logger.setLevel(logging.DEBUG)

import pprint
pp = pprint.PrettyPrinter(indent=4)

# default daemon-port
default_port = 8300
default_threads = '8'
snark_worker_fee = '1'
default_sleep = 3

##############################################################################
""" cli wrapper """
def console(cmd, verbose=False):
    if verbose:
        print('Running:', cmd)

    p = Popen(cmd, shell=True, stdout=PIPE)
    out, err = p.communicate()
    if p.returncode != 0:
        print('WARNING: Non 0 return code running cmd: %s' % (cmd))
        print(err)
    else:
        if verbose:
            print('Result:', out.decode())
    return (p.returncode, out, err)

##############################################################################
# Coda functions (wrappers for coda commands)


def coda_config(name='NONE', baseport=8300):
    # Create configuration directory if it doesn't yet exist
    dir_name = '%s/test-%s' % (os.getcwd(), name)
    if not os.path.exists(dir_name):
        os.mkdir(dir_name)

    # Create a configuration file
    config = {
        'external-port': baseport + 2,
        'rest-port':     baseport + 4
    }
    with open('%s/daemon.json' % (dir_name), 'w') as fp:
        json.dump(config, fp)
    return(dir_name)


""" Get daemon status """
def coda_status(port=default_port+1, verbose=False):
    cli = "coda client status -json -daemon-port %s" % (port)
    (code, out, err) = console(cli, verbose=verbose)
    if code == 0:
        try:
            return(json.loads(out.decode('utf-8')))
        except json.decoder.JSONDecodeError:
            return(dict())
    else:
        print('ERROR:', err)
        return(dict())

def coda_block(port=default_port+1, verbose=False):
    status = coda_status(port=port, verbose=verbose)
    if 'block_count' in status:
        return(status['block_count'])
    else:
        print('Unable to determine current block. Sleeping %s' % (default_sleep))
        time.sleep(default_sleep)
        return(False)

def coda_slot(port=default_port+1, verbose=False):
    status = coda_status(port=default_port+1, verbose=verbose)
    if 'consensus_time_now' in status:
        return(status['consensus_time_now'])
    else:
        print('Unable to determine current slot. Sleeping %s' % (default_sleep))
        time.sleep(default_sleep)
        return(False)

# --------------------------------------------------------------------------------
""" Start a daemon """
def coda_start(config_directory='.coda',
               default_port=default_port,
               peer=False,
               propose=False,
               snark=False,
               snark_worker=False,
               threads=0):

    client_port = default_port + 1

    print('-'*80)
    msg='Starting coda on port %s' % client_port

    cli = "coda daemon -background -ip 127.0.0.1"
    cli += " -client-port %s" % (client_port)
    cli += " -config-directory %s" % (config_directory)
    cli += " -tracing"

    if peer:
        cli += " -peer %s" % (peer)

    if propose:
        # DO NOT limit threads for proposer
        if 'OMP_NUM_THREADS' in os.environ:
            del os.environ['OMP_NUM_THREADS']

        cli += " -propose-key %s" % (propose)

    if snark and snark_worker:
        msg='Starting snark worker'
        os.environ['OMP_NUM_THREADS'] = default_threads
        id = uuid.uuid4().hex.upper()[0:8]
        os.mkdir('test-snark-worker-%s' % id)
        cli = "nohup coda internal snark-worker"
        cli += " -public-key %s" % (snark)
        cli += " -daemon-address 10.111.4.68:8501"  # FIXME 127.0.0.1 not working?
        cli += " -shutdown-on-disconnect true"
        cli += " >> test-snark-worker-%s/coda.log &" % (id)

    elif snark and not snark_worker:
        # limit threads for snarkers
        os.environ['OMP_NUM_THREADS'] = default_threads
        cli += " -run-snark-worker %s" % (snark)
        cli += " -snark-worker-fee %s" % (snark_worker_fee)

         # whitelist office
        print("whitelist file %s"% (config_directory))
        with open('%s/client_whitelist' % (config_directory), 'w') as f:
            f.write("( 127.0.0.1 ")
            for ip in range(2,199):
                f.write("10.111.4.%s " % (ip))
            f.write(")")
    print(msg)

    # start the daemon
    console(cli, verbose=True)


# Stop a daemon
def coda_stop(port=default_port):
    print('-'*80)
    print('Stopping coda on port %s' % port)
    cli = "coda client stop-daemon -daemon-port %s" % (port)
    (code, out, err) = console(cli)
    if code == 0:
        return(out)
    else:
        return(err)


# --------------------------------------------------------------------------------
""" identify coda processes and daemon-ports """
def coda_processes():
    client_ports = []
    for proc in psutil.process_iter(attrs=['name', 'cmdline']):
        if 'coda' == proc.info['name']:
            cmdline = proc.info['cmdline']
            for i in range(len(cmdline)):
                if cmdline[i] == "-client-port":
                    client_ports.append('%s' % cmdline[i+1])
    return(client_ports)


""" Stripped down client status output """
def filtered_status(client_port=None):
    output = {}
    # skip overly verbose keys we don't care about here
    skip_list = [
        'commit_id',
        'consensus_configuration',
        'consensus_mechanism',
        'consensus_time_best_tip',
        'external_transition_latency',
        'histograms',
        'ledger_builder_hash',
        'ledger_merkle_root',
        'run_snark_worker',
        'snark_worker_merge_time',
        'snark_worker_merge_time',
        'snark_worker_transition_time',
        'staged_ledger_hash',
    ]
    metrics = coda_status(port=client_port)

    # skip empty/broken metrics
    if len(metrics) < 1:
        return(dict())

    # calculated metrics
    metrics['human_uptime'] = seconds_to_human(metrics['uptime_secs'])
    metrics['human_epoch'] = seconds_to_human(metrics['consensus_configuration']['epoch_duration']/1000)
    metrics['epochs_passed'] = int(( metrics['uptime_secs'] / (metrics['consensus_configuration']['epoch_duration']/1000) ))
    metrics['seconds_per_block'] = int(metrics['uptime_secs'] / metrics['block_count'])

    output = {key: metrics[key] for key in metrics if key not in skip_list}

    # shorten long values
    for key in output:
        if type(output[key]) is str:
            output[key] = output[key][-25:]


    return(output)

""" Get status from all running daemons """
def cluster_status():
    portlist = coda_processes()
    # Run client status in parallel (fast!)
    if len(portlist) < 1:
        print('No coda daemons found')
        sys.exit(0)
        return

    with Pool(processes=len(portlist)) as pool:
        results = pool.map(filtered_status, portlist)

    stats = defaultdict(Counter)
    for result in results:
        if len(result) < 1: continue

        statkeys = ['state_hash', 'num_accounts', 'block_count']
        for stat in statkeys:
            if stat in result:
                stats[stat][result[stat]] += 1
        print(json.dumps(result, sort_keys=True, indent=4))


""" Stop all running coda daemons """
def cluster_stop():
    result = False
    for client_port in coda_processes():
        coda_stop(port=client_port)
        result = result or True
    return result


def log_clean():
    dirlist = glob.glob("test-*")
    for dir in sorted(dirlist):
        print('Removing Dir: %s' % dir)
        shutil.rmtree(dir)


def init_cluster(
        seeds=1,
        proposers=2,
        proposer_private_keys=[],
        snark_coordinator=1,
        snark_workers=0,
        snark_private_file='',
        snark_public_key=''):

    # stop running cluster if it's there
    while cluster_stop():
       print('Sleeping...')
       time.sleep(5)

    # remove old config dirs
    log_clean()

    for i in range(1, seeds + 1):
        coda_start(
            config_directory=coda_config(
                name='seed-%s' % i,
                baseport=8300),
            peer=False
        )
        # delay after a seed
        time.sleep(5)

    for i in range(1, proposers + 1):
        propose_key = proposer_private_keys[i-1]
        baseport = 8400 + (10*i)
        coda_start(
            config_directory=coda_config(
                name='proposer-%s' % i, baseport=baseport),
            default_port=baseport,
            peer="127.0.0.1:8303",
            propose=propose_key)

    for i in range(1, snark_coordinator + 1):
        coda_start(
            config_directory=coda_config(
                name='snark_coordinator-%s' % i, baseport=8500),
            default_port=8500,
            peer="127.0.0.1:8303",
            snark=snark_public_key)
        i += 1

    if snark_workers > 0:
        print('Sleeping....')
        time.sleep(10)
    for i in range(snark_workers):
        coda_start(snark_worker=True,
                   snark=snark_public_key,
                   threads=8)

# --------------------------------------------------------------------------------
""" Get balances """
def coda_get_balances(port=default_port, verbose=False):
    cli = "coda client get-public-keys "
    cli += "-with-balances -json -daemon-port %s" % (int(port))
    (code, out, err) = console(cli, verbose=verbose)
    output = {}
    if code == 0:
        accounts = json.loads(out.decode('utf-8'))['accounts']
        # flip publickey and balance amount
        for account in accounts:
            for key in account.keys():
                output[key] = account[key]
        #print(output)
        return(output)
    else:
        return(err)

def coda_get_balance(key, port=default_port):
    balances = coda_get_balances(port=port)
    if key in balances:
        return balances[key]
    else:
        return 0

def random_accounts(count=1, max_balance=9000, port=default_port):
    balances = coda_get_balances(port=port)

    # strip out accounts with balances above a threshold
    for key in list(balances.keys()):
        if balances[key] > max_balance:
            del balances[key]

    all_accounts = balances.keys()
    accounts = random.sample(all_accounts, count)
    return accounts

""" create key """
def coda_create_key():
    # random id
    id = uuid.uuid4().hex.upper()[0:8]
    cli = "coda client generate-keypair  -privkey-path testkeys/%s" % (id)
    (_, out, _) = console(cli)
    key = out.decode().split(':')[1].strip()
    return(key)

""" create a list of keys"""
def coda_create_keys(count=1):
    keys = []
    for i in range(count):
        keys.append(coda_create_key().strip())
    return(keys)

""" send a single transaction """
def coda_send_transaction(from_keypath, to_keys, amount=50, fee=1, verbose=True, port=default_port):
    # only process first key
    to_key = to_keys[0]
    cli = "coda client send-payment"
    cli += " -amount %s" % (amount)
    cli += " -fee %s" % (fee)
    cli += " -privkey-path %s" % (from_keypath)
    cli += " -receiver %s" % (to_key)
    cli += " -daemon-port %s" % (port)
    # FIXME: Parse out and return the receipt ID
    console(cli, verbose=verbose)

""" send a group of transactions """
def coda_send_batch_transactions(from_keypath, to_keys, amount=50, fee=4, port=default_port+1):
    bulk = []
    for dest in to_keys:
        bulk.append([['receiver', dest], ['amount', amount], ['fee', fee]])

    dir_name = '%s/batches' % (os.getcwd())
    if not os.path.exists(dir_name):
        os.mkdir(dir_name)

    batch_file = '%s/batch_transaction.sexp' % (dir_name)
    with open(batch_file, 'w') as fp:
        fp.write(sexpdata.dumps(bulk))

    cli = "coda client batch-send-payments"
    cli += " -privkey-path %s" % (from_keypath)
    cli += " -daemon-port %s" % (port)
    cli += " %s" % batch_file

    console(cli, verbose=True)

""" utility for job_list parsing/pruning """
def traverse(obj):
    if isinstance(obj, dict):
        return {k: traverse(v) for k, v in obj.items() if k not in ['Fee Excess']}
    elif isinstance(obj, list):
        return [traverse(elem) for elem in obj]
    else:
        # prune long strings to 8 characters
        if isinstance(obj, str):
            return obj[:8]
        else:
            return obj

def coda_snark_job_list(port=default_port +1, verbose=False):
    cli = "coda client snark-job-list"
    (code, out, err) = console(cli, verbose=verbose)
    if code == 0:
        return(traverse(json.loads(out.decode('utf-8'))))
    else:
        return(err)

def pretty_time_delta(seconds):
    seconds = int(seconds)
    days, seconds = divmod(seconds, 86400)
    hours, seconds = divmod(seconds, 3600)
    minutes, seconds = divmod(seconds, 60)
    if days > 0:
        return '%dd%dh%dm%ds' % (days, hours, minutes, seconds)
    elif hours > 0:
        return '%dh%dm%ds' % (hours, minutes, seconds)
    elif minutes > 0:
        return '%dm%ds' % (minutes, seconds)
    else:
        return '%ds' % (seconds,)

""" functional programming!  -- loop that runs a function once per block """
def each_block(fnc, maxblock=999, pretty=False):
    last_block = None
    while(True):
        current_block = coda_block()
        current_slot = coda_slot()
        if last_block != current_block:
            data = {}
            #print('-'*80)
            #print('')
            data['timestamp'] = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            data['current_block'] = current_block
            data['current_slot'] = current_slot
            last_block = current_block
            data['output'] = fnc()
            print(json.dumps(data))
            sys.stdout.flush()
        time.sleep(5)

""" convert seconds to human friendly values """
def seconds_to_human(sec):
    if sec <= 60:
        out="%s seconds" % sec
    elif sec <= 3600:
        minutes = sec / 60
        out="%.1f minutes" % minutes
    #elif sec <= 86400:
    else:
        hours = sec / 3600
        out = "%.1f hours" % hours
    return(out)

""" Print represensntation of current snark tree """
def print_snark_tree():
    # recursively prune strings to 8 characters
    results = coda_snark_job_list()

    # Prune results to only show non-empty records.
    output = []
    for node in results:
        if 'M' in node[1] and 'Source' in node[1]['M'][0]:
            output.append(node)
            #print(json.dumps(node))
        elif 'B' in node[1] and 'Source' in node[1]['B'][0]:
            output.append(node)
            #print(json.dumps(node))
    return(output)
