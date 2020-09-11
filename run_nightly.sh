#!/bin/bash


rm -rf scripts/offline_whale_keys
rm -rf scripts/offline_fish_keys
rm -rf scripts/online_whale_keys
rm -rf scripts/online_fish_keys
rm -rf scripts/service-keys

python3 scripts/testnet-keys.py keys  generate-offline-fish-keys --count 2
python3 scripts/testnet-keys.py keys  generate-online-fish-keys --count 2
python3 scripts/testnet-keys.py keys  generate-offline-whale-keys --count 3
python3 scripts/testnet-keys.py keys  generate-online-whale-keys --count 3

python3 scripts/testnet-keys.py ledger generate-ledger --num-whale-accounts 3 --num-fish-accounts 2

#"codaprotocol/coda-daemon:0.0.15-beta-develop"

./scripts/auto-deploy.sh pickles-nightly
