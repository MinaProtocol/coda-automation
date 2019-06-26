#!/usr/bin/env python3

import json
import pprint
pp = pprint.PrettyPrinter(indent=4)
"""
FORMAT:
(((receiver KM2VADbB/WVDSMVh6bIVKFbZAUSGJ12cYNwMV3hajHAuZftwpc8CAAAB)
  (amount 10) (fee 88))
 ((receiver KJZwYXkRRTgdoZ2j+IgZRRfO9v518Je7S+VwQHrWqn3IGwYfix4BAAAA)
  (amount 42) (fee 33))
 ((receiver KDQu+q7J3un1WOLq6Oc8dVAZTjw89d+OPVrJ1PFKNMYNLOAWS2oCAAAA)
  (amount 79) (fee 64)))
"""

with open('balances.json') as f:
    data = json.load(f)['accounts']

print("(")
count = 1
for line in data:
  amount = line[0]
  pub = line[1]
  if amount == 1000 or amount == 0:
    continue
  if count > 0 and count <= 900:
    print("((receiver {}) (amount {}) (fee 0)".format(pub, amount))
  count+=1
print(")")
