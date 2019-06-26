# Python pseudo-library managing daemon start/stop/operations

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
import codalib
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


""" functional programming!  -- loop that runs a function once per block """
def each_block(fnc, maxblock=999, pretty=False):
    last_block = None
    while(True):
        current_block = codalib.coda_block()
        current_slot = codalib.coda_slot()
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
