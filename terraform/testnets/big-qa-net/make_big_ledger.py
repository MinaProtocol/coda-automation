
import json


def main():
  with open('genesis_ledger_original.json', 'r') as f:
    ledger = json.loads(f.read())

  def make_extra_account(i):
    letters = 'abcdefghijklmnopqrstuvwxyz'
    postfix = ''#''.join([ letters[j] for j in number_to_base(i, len(letters)) ])
    pk = "B62qmNhxRDDiHG9evttEUGEBT4tbJyr3V2LkXqL2JEX83Atwz5nhbVx"
    pk = pk[:len(pk) - len(postfix)] + postfix
    return {
          "pk": pk,
          "balance": "1.000000000",
          "delegate": pk,
          "sk": None
        }

  for i in range(30000):
    ledger['ledger']['accounts'].append(make_extra_account(i))

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
