#!/bin/bash

python3 scripts/testnet-keys.py keys  generate-offline-fish-keys --count 10
python3 scripts/testnet-keys.py keys  generate-online-fish-keys --count 10
python3 scripts/testnet-keys.py keys  generate-offline-whale-keys --count 5
python3 scripts/testnet-keys.py keys  generate-online-whale-keys --count 5
python3 scripts/testnet-keys.py keys  generate-service-keys

python3 scripts/testnet-keys.py ledger generate-ledger
