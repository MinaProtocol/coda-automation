#!/bin/bash

set -e

python3 /scripts/random_restart.py -n '' -i 60 -ic true &

while true; do
  sleep 60
done
