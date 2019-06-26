#!/bin/bash

# grep -- look at a proposer's log file for Block Info and stat

grep -i 'Block Info\|Block stat' test-proposer*/coda.log  | tail -n 80
