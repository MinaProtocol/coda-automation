from __future__ import print_function
def add(old, new):
    return int(old) + int(new)

def max_metric(old, new):
    return max(int(old), int(new))

def latest(_old, new):
    return new

def no_update(old, _new):
    return old

combine_fns = {
    "metric1": latest,
    "metric2": max_metric,
    "metric4": latest,
}

