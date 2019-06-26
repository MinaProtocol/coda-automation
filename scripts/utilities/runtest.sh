#!/bin/bash

## DEPRECATED

echo "Starting tree logging."
mkdir test-logs
./tree > test-logs/tree.log . &

echo "Waiting for block 5"
./block_wait 5

echo "Starting transaction loop log"
./transactions.py &> test-logs/transaction.log &
