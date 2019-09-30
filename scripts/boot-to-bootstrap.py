#!/usr/bin/env python3

"""
    Simple script to parse coda daemon json logs and
    measure time to bootstrap relative to boot (daemon start)
"""

import json
import datetime


def get_timestamp(line):
    data = json.loads(line)
    if 'timestamp' in data:
        dt = datetime.datetime.strptime(
            data['timestamp'], '%Y-%m-%d %H:%M:%S.%fZ')
        return(dt.timestamp())


with open('test-coda/coda.log', 'r') as f:
    for line in f:
        if 'Coda daemon is booting up' in line:
            t0 = get_timestamp(line)
            print('Found boot time: %0.2f' % t0)

        elif 'Bootstrap state: complete' in line:
            t1 = get_timestamp(line)
            print('Found bootstrap completion time: %0.2f' % t1)
            print('Delta: %0.2f seconds' % (t1-t0))
