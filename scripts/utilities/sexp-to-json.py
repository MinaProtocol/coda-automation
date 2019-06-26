#!/usr/bin/python

"""Simple test script for testing hacky sexp to json conversions"""

import fileinput
import sexpdata
import pprint

pp = pprint.PrettyPrinter(indent=4)


def unroll(nest):
    values = []
    if type(nest) is list:
        for element in nest:
            if type(element) is list:
                values.append(unroll(element))
            elif type(element) is str:
                values.append(str(element))
            else:
                values.append(element.value())
    else:
        if type(nest) is str or type(nest) is int:
            values.append(str(nest))
        else:
            values.append(nest.value())
    return(" ".join(values))


for line in fileinput.input():
    try:
        data = sexpdata.loads(line)
    except (AssertionError,
            sexpdata.ExpectClosingBracket,
            sexpdata.ExpectNothing) as e:
        continue

    # Non sexp line
    if type(data) is not list:
        continue

    print('-'*80)
    print(line)

    output = {}
    for field in data:
        # skip empty values
        if field[1] == []:
            continue

        # deal with nested values
        output[field[0].value()] = unroll(field[1])
    pp.pprint(output)
