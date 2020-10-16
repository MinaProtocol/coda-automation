#!/bin/bash

export CODA_PRIVKEY_PASS="naughty blue worm"
for i in {1..251}
do
  coda advanced generate-keypair -privkey-path ./keys/keypairs/
  echo "Generated $i privkey"
done
