#! /bin/bash

TESTNET="${1:-pickles-public}"
COMMUNITY_SIZE="${2:-10}"

mkdir ./keys/keysets && mkdir ./keys/keypairs && mkdir ./keys/genesis

./bin/coda-network keyset create --count 10 --name ${TESTNET}_offline-whales
./bin/coda-network keyset create --count 10 --name ${TESTNET}_online-whales

./bin/coda-network keyset create --count $COMMUNITY_SIZE --name ${TESTNET}_offline-fish
./bin/coda-network keyset create --count $COMMUNITY_SIZE --name ${TESTNET}_online-fish

./bin/coda-network keyset create --count 2 --name ${TESTNET}_online-service-keys

echo "-- Generated the following keypairs and keysets for use in ./bin/coda-network genesis --"
ls -R ./keys

#./bin/coda-network genesis <<KEYSETS
#${TESTNET}_offline-fish
#1000
#${TESTNET}_online-fish
#y
#${TESTNET}_online-fish
#10
#${TESTNET}_online-fish
#y
#${TESTNET}_offline-whales
#1000000
#${TESTNET}_online-whales
#y
#${TESTNET}_online-service-keys
#1000000
#${TESTNET}_online-service-keys
#n
#KEYSETS
