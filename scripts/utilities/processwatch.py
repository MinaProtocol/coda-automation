#! /usr/bin/env python3

""" script to track user cpu % by process family for coda """

from collections import Counter
import psutil

debug=False

def process_watch():
    usertime_parent = Counter()  # single process
    usertime_subprocess = Counter() # child processes
    parents = {} # keep cmdline for parent pids

    for p in psutil.process_iter(attrs=['cmdline', 'cpu_times', 'pid', 'ppid']):
        try:
            cmdline = " ".join(p.info['cmdline'])
            if 'coda' in cmdline or 'coda internal snark-worker' in cmdline \
                                or 'parallel-worker' in cmdline \
                                or 'coda-kademlia' in cmdline:
                user_cpu = int(p.info['cpu_times'].user)
                pid      = p.info['pid']
                ppid     = p.info['ppid']

                if debug:
                    print(ppid, pid, cmdline)

                # Daemon and nohup processes are owned by parent pid 1
                if ppid == 1:
                    parents[pid] = cmdline
                    usertime_parent[pid] += user_cpu
                elif "coda internal snark-worker" in cmdline and "/usr/local/bin/coda" not in cmdline:
                    parents[pid] = cmdline
                    usertime_parent[pid] += user_cpu
                else:
                    usertime_subprocess[ppid] += user_cpu
        except psutil.NoSuchProcess:
            continue

    usertime_family = Counter()
    print('='*80)
    print('CPU usertime By Process Tree\nPARENT \t CHILDREN \t PARENT_CMDLINE')
    for pid in parents:
        print(usertime_parent[pid], '\t',
            usertime_subprocess[pid], '\t\t', parents[pid], )
        cmdline = parents[pid]

        # family classifications
        key_words = ['snark-worker', 'proposer', 'seed']
        for word in key_words:
            if word in cmdline:
                usertime_family[word] += (usertime_parent[pid] + usertime_subprocess[pid])
        usertime_family['total'] += (usertime_parent[pid] + usertime_subprocess[pid])

    print('='*80)
    print('CPU Usertime By Family\nRaw \t % \t Family')
    for family in usertime_family.keys():
        if family == 'total': continue
        ratio = int(usertime_family[family]/usertime_family['total'] * 100)
        print(usertime_family[family], '\t', ratio, '\t', family)

if __name__ == '__main__':
    process_watch()