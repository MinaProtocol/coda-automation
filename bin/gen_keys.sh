#!/bin/bash

export CODA_PRIVKEY_PASS="naughty blue work"
for i in {1..251}
do
  coda advanced generate-keypair -privkey-path /usr/local/var/coda-network/keypairs/
  echo "Generated $i privkey"
done
