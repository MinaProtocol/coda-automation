
import json


def main():
  with open('genesis_ledger.json', 'r') as f:
    ledger = json.loads(f.read())

  def set_account(a):
    if a['balance'] == '66000.000000000':
      a['balance'] = '1.000000000'
      a['timing']['initial_minimum_balance'] = '1.000000000'
      a['timing']["cliff_time"] = "150"
      a['timing']["cliff_amount"] = "1"
      a['timing']["vesting_period"] = "6"
      a['timing']["vesting_increment"] = "1"


  [ set_account(a) for a in ledger['ledger']['accounts'] ]

  #import IPython; IPython.embed()

  #def make_extra_account(i):
  #  letters = 'abcdefghijklmnopqrstuvwxyz'
  #  postfix = ''#''.join([ letters[j] for j in number_to_base(i, len(letters)) ])
  #  pk = "B62qmNhxRDDiHG9evttEUGEBT4tbJyr3V2LkXqL2JEX83Atwz5nhbVx"
  #  pk = pk[:len(pk) - len(postfix)] + postfix
  #  return {
  #        "pk": pk,
  #        "balance": "1.000000000",
  #        "delegate": pk,
  #        "sk": None
  #      }

  #for i in range(30000):
  #  ledger['ledger']['accounts'].append(make_extra_account(i))

  with open('genesis_ledger.json', 'w') as f:
    json.dump(ledger, f, indent=2)


def number_to_base(n, b):
  if n == 0:
    return [0]
  digits = []
  while n:
    digits.append(int(n % b))
    n //= b
  return digits[::-1]

main()
