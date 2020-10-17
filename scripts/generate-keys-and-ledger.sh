#! /bin/bash

TESTNET="${1:-pickles-public}"
COMMUNITY_SIZE="${2:-10}"

mkdir ./keys/keysets
mkdir ./keys/keypairs
rm -rf ./keys/genesis && mkdir ./keys/genesis

for keyset in online-whales offline-whales online-fish offline-fish; do
  [[ -s "keys/keysets/${TESTNET}_${keyset}" ]] || coda-network keyset create --count 10 --name "${TESTNET}_${keyset}"
done

[[ -s "keys/keysets/${TESTNET}_online-service-keys" ]] || coda-network keyset create --count 2 --name ${TESTNET}_online-service-keys


if [[ -s "keys/testnet-keys/${TESTNET}_online-whale-keyfiles/online_whale_account_1.pub" ]]; then
echo "using existing keys"
else
  # Recreate + replace the online whale keys with ones we can put in secrets
  sed -i 's/"publicKey":"[^"]*"/"publicKey":"PLACEHOLDER"/g' keys/keysets/${TESTNET}_online-whales
  python3 ./scripts/testnet-keys.py keys generate-online-whale-keys --count 10 --output-dir $(pwd)/keys/testnet-keys/${TESTNET}_online-whale-keyfiles
fi

for f in keys/testnet-keys/${TESTNET}_online-whale-keyfiles/*.pub; do
  echo "s/PLACEHOLDER/$(cat $f)/"
  sed -i "s/PLACEHOLDER/$(cat $f)/" keys/keysets/${TESTNET}_online-whales
done
cat keys/keysets/${TESTNET}_online-whales

# Generate the ledger
echo
echo "-- Generated the following keypairs and keysets for use in ./bin/coda-network genesis --"
ls -R ./keys

echo "ENTER THE FOLLOWING AT THE PROMPTS IN ORDER:"

cat <<KEYSETS
${TESTNET}_offline-fish
60000
${TESTNET}_online-fish
y
${TESTNET}_online-fish
5000
${TESTNET}_online-fish
y
${TESTNET}_offline-whales
39000
${TESTNET}_online-whales
y
${TESTNET}_online-service-keys
39000
${TESTNET}_online-service-keys
n
KEYSETS

coda-network genesis

# Fix the ledger format for ease of use
cat ./keys/genesis/* | jq '[.[] | . + { sk: null, delegate: .delegate, balance: (.balance + ".000000000") }]' | cat > terraform/testnets/${TESTNET}/genesis_ledger.json
