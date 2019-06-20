#!/bin/bash

# --------------------------------------------------------------------------------
echo 'Starting snark worker'

if [ -z "$1" ]
  then
    DAEMON='127.0.0.1:8301'
else
    DAEMON=$1
fi

export OMP_NUM_THREADS=8
NEW_UUID=$(cat /dev/urandom | LC_CTYPE=C tr -dc 'A-Z0-9' | fold -w 8 | head -n 1)
echo ${NEW_UUID}
mkdir test-snark-worker-${NEW_UUID}
nohup coda internal snark-worker \
    -public-key 8QnLTHMZPbBFezS8j8kDPu6iLiwPsTPyX2vMwcFzjiDZbp6GQDEBEyLbYvzApSdTsE \
    -daemon-address $DAEMON \
    -shutdown-on-disconnect false  2>&1 >> test-snark-worker-${NEW_UUID}/coda.log &
