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


with open('test-coda/coda.log', 'rb') as f:
    for line_bare in f:
        line = line_bare.decode(errors='ignore')
        if 'Coda daemon is booting up' in line:
            t0 = get_timestamp(line)
            print('Found boot:                    %0.2f' % t0)
        elif 'curr_global_slot' in line:
            # no-op for now - but want to collect later
            continue
        # Bootstrap starts at 2k+delta
        elif 'Starting Bootstrap Controller' in line:
            tb1 = get_timestamp(line)
            print('Found bootstrap start:         %0.2f' % tb1)

        elif 'Bootstrap state: complete' in line:
            tb2 = get_timestamp(line)
            print('Found bootstrap completion:    %0.2f' % tb2)
            print('')
            print('Seconds to begin bootstrap:    %0.2f' % (tb1-t0))
            print('Seconds to bootstrap:          %0.2f' % (tb2-tb1))
            print('')

        elif 'Coda daemon is now doing ledger catchup' in line:
            tc1 = get_timestamp(line)
            print('Found catchup start:           %0.2f' % tc1)

        elif 'Coda daemon is now synced' in line:
            tc2 = get_timestamp(line)
            try:
                tc1
                print('Found catchup complete:        %0.2f' % tc2)
                print('')
                print('Seconds to catchup:            %0.2f' % (tc2-tc1))
                print('Seconds to sync (from boot):   %0.2f' % (tc2-t0))
            except:
                pass