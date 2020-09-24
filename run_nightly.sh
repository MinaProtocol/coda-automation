#!/bin/bash

genkeys=${1:-"generate-keys"}
deploy=${2:-"deploy"}

logproc=${3:-"~/gits/coda/_build/default/src/app/logproc/logproc.exe"}

#===================================
if [ $genkeys == "generate-keys" ]; then
  echo "preparing keys and ledger"

  rm -rf scripts/offline_whale_keys
  rm -rf scripts/offline_fish_keys
  rm -rf scripts/online_whale_keys
  rm -rf scripts/online_fish_keys
  rm -rf scripts/service-keys

  python3 scripts/testnet-keys.py keys  generate-offline-fish-keys --count 10
  python3 scripts/testnet-keys.py keys  generate-online-fish-keys --count 10
  python3 scripts/testnet-keys.py keys  generate-offline-whale-keys --count 10
  python3 scripts/testnet-keys.py keys  generate-online-whale-keys --count 10

  python3 scripts/testnet-keys.py ledger generate-ledger --num-whale-accounts 10 --num-fish-accounts 10
fi

# ===================================
if [ $deploy == "deploy" ]; then
  echo "deploying network"
  ./scripts/auto-deploy.sh pickles-nightly
fi

# ===================================
echo "getting version"

version=$(./scripts/get_version.sh pickles-nightly)
while [ -z "$version" ]; do
  echo "retrying..."
  version=$(./scripts/get_version.sh pickles-nightly);
  sleep 5;
done

echo "version: $version"

mkdir -p nightly-logs/$version/

# ===================================
echo "collecting logs"

while true; do 
  ./scripts/get_fatal_logs_by_machine.sh pickles-nightly $logproc nightly-logs/$version/

  python3 scripts/testnet-validation/compare_best_tip.py --namespace pickles-nightly --hide-graph &>/dev/null

  current_time=$(date "+%Y.%m.%d-%H.%M.%S")
  mv Digraph.gv.png nightly-logs/$version/graph.$current_time.png

  sleep 600; 
done
