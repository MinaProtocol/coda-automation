#!/usr/bin/env python3
from fabric2 import ThreadingGroup, Connection
import json
from collections import Counter, defaultdict

# Reads an ansible inventory -- assumes ec2 nodes -- strips out extra data
def read_ansible_inventory(fname):
    hostlist = []
    with open(fname) as f:
        lines = f.readlines()
        for line in lines:
            if line.startswith("ec2"):
                data = line.split()
                hostlist.append(data[0])
    return(hostlist)


# existing utility scripts already deployed
def crashhash(group):
    cmd = '/home/admin/scripts/crashhash.py'
    return group.run(cmd, hide='both', warn=True)

def status(group):
    cmd = '/home/admin/scripts/status.py'
    return group.run(cmd, hide='both', warn=True)


def get_trust_status_all(group):
    cmd = 'coda client get-trust-status-all'
    return group.run(cmd, hide='both', warn=True)

def hostname(group):
    cmd = 'hostname'
    return group.run(cmd, hide='both', warn=True)

def print_results(results):
    for connection, result in results.items():
        if len(result.stdout) > 0:
            print('*'*80)
            print("{0.host}\n{1.stdout}".format(connection, result))

def print_summary(results):
    summary = defaultdict(Counter)
    for connection, result in results.items():
        if len(result.stdout) > 0:
            try:
                data = json.loads(result.stdout)
                for key in data:
                    if key == 'propose_pubkeys': continue
                    if key == 'conf_dir': continue
                    try:
                        summary[key].update([data[key]])
                    except:
                        print('Error working with', key, data[key])
            except json.decoder.JSONDecodeError:
                print('Unable to parse response json from host: {0.host}'.format(connection))
    for key, counts in summary.items():
        print("\t",key)
        for item, count in counts.items():
             print("\t\t", count, "@", item)

def tar_logs(group):
    cmd = 'tar -zcvf runlog.tar.gz test-*'
    results = group.run(cmd, hide='both', warn=True)
    for connection, result in results.items():
        print('*'*80)
        print("{0.host}\n{1.stdout}".format(connection, result))

def copy_back(hosts, getfilename):
    for host in hosts:
        savefilename = 'log-%s.tar.gz' % (host)
        print(savefilename)
        Connection(host).get(getfilename, local=savefilename)

def package_check(group):
    cmd = 'dpkg -l | grep coda-post'
    results = group.run(cmd, hide='both', warn=True)
    return results

def package_fix(group):
    cmds = [
        'sudo apt-get update',
        'sudo apt-get --only-upgrade install coda-testnet-postake-many-proposers=0.1.89463-CI',
    ]
    for cmd in cmds:
        group.run(cmd, hide='both', warn=True)
