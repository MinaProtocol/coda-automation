#!/bin/bash

# scale up OPENMP and measure results

max=`nproc --all`

mkdir -p OMP-test-results

for i in `seq 1 ${max}`;
do
    echo $i
    export OMP_NUM_THREADS="${i}"
    coda transaction-snark-profiler > OMP-test-results/OMPTEST-LOG-${i}.log
done
