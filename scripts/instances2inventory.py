#!/usr/bin/env python3

import boto
import boto.ec2
import sys

from pprint import pprint

from collections import defaultdict

output = defaultdict(lambda: [])
comments = defaultdict(lambda: {})
skip_region_strings = ['us-gov', 'cn-', 'ca-']
#skip_region_strings = ['us-gov', 'cn-', 'ca-', 'eu-', 'ap-']

if len(sys.argv) > 1:
  filter = sys.argv[1]
else:
  filter = False

regions = boto.ec2.regions()

for region in regions:
  if any (skip_string in region.name for skip_string in skip_region_strings):
    continue

  print('# Querying region:', region)

  ec2conn =  boto.connect_ec2(region=region)
  reservations = ec2conn.get_all_instances()

  instances = [i for r in reservations for i in r.instances]
  for i in instances:

    if filter:
      if 'Name' in i.tags:
        if filter not in i.tags['Name']:
          continue

    if 'running' not in i.state:
      continue

    if 'Name' in i.tags:
      if 'Packer' in i.tags['Name']: continue

      if i.tags['Name'].count('_') == 2:
        try:
          (net, group, num) = i.tags['Name'].split('_')
          myregion = region.name
        except:
          print('Error parsing ', i.tags['Name'])
          continue

      elif i.tags['Name'].count('_') == 3:
        try:
          (net, myregion, group, num) = i.tags['Name'].split('_')
        except:
          print('Error parsing ', i.tags['Name'])
          continue
      groupname = "%ss" % group

    else:
      print('NONAME', end='')
      groupname = 'unknown'
      i.tags['Name'] = 'NONE'

    output[groupname].append(i.public_dns_name)
    comments[groupname][i.public_dns_name] = "# %s\t%s\t%s\t%s\t%s" % (i.tags['Name'], myregion, i.instance_type, i.ip_address, i.launch_time)

for group in output:
  print("[%s]" % group)
  hostlist = output[group]
  hostlist.sort()
  for host in hostlist:
    print("%s \t%s" % (host, comments[group][host]))
  print("\n")
