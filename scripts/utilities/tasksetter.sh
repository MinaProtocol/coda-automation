#!/bin/bash

# simple script to isolate snark-worker process and threads 
# to a fixed set of cores and keep the scheduler from moving them around
# this improves overall performance by about 10%

cpus=$(nproc --all)
start=0
cores_per_process=4

for pid in $(pgrep -f 'coda internal snark-worker')
do
    end=$((start + cores_per_process - 1))
    taskset -a -pc $start-$end $pid
    start=$((start + cores_per_process))
done
