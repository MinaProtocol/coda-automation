#! /usr/bin/env python3

""" script to track user cpu for a single process """

import psutil
import time
import sys

def get_cpu(pid):
    p = psutil.Process(pid=pid)
    return(p.cpu_times().user)

def process_watch(pid):
    sleep_interval = 0.5
    cpu_last = None
    while True:
        cpu_current = get_cpu(pid)
        if cpu_last:
            cpu_diff = cpu_current - cpu_last
            ratio = cpu_diff / sleep_interval
            print("%s,%0.2f,%0.2f" % (pid, time.time(), ratio))
            sys.stdout.flush()
        cpu_last = cpu_current
        time.sleep(sleep_interval)

if __name__ == '__main__':
    pid = sys.argv[1]
    process_watch(pid=int(pid))