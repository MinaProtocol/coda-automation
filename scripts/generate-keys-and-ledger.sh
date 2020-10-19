#! /bin/bash

# ARGS
TESTNET="${1:-pickles-public}"
COMMUNITY_KEYFILE="${2:-community-keys.txt}"

# DIRS
mkdir ./keys/keysets
mkdir ./keys/keypairs
rm -rf ./keys/genesis && mkdir ./keys/genesis

set -eo pipefail

# WHALES
for keyset in online-whales offline-whales; do
  [[ -s "keys/keysets/${TESTNET}_${keyset}" ]] || coda-network keyset create --count 10 --name "${TESTNET}_${keyset}"
done

if [[ -s "keys/testnet-keys/${TESTNET}_online-whale-keyfiles/online_whale_account_1.pub" ]]; then
echo "using existing whale keys"
else
  # Recreate the online whale keys with ones we can put in secrets
  sed -i 's/"publicKey":"[^"]*"/"publicKey":"PLACEHOLDER"/g' keys/keysets/${TESTNET}_online-whales
  python3 ./scripts/testnet-keys.py keys generate-online-whale-keys --count 10 --output-dir $(pwd)/keys/testnet-keys/${TESTNET}_online-whale-keyfiles
fi

# Replace the whale keys with the ones generated by testnet-keys.py
for file in keys/testnet-keys/${TESTNET}_online-whale-keyfiles/*.pub; do
  sed -i "s/PLACEHOLDER/$(cat $file)/" keys/keysets/${TESTNET}_online-whales
done
echo "Online Whale Keyset:"
cat keys/keysets/${TESTNET}_online-whales
echo

# FISH / COMMUNITY
declare -a PUBKEYS
PUBKEYS=$(cat $COMMUNITY_KEYFILE)
COMMUNITY_SIZE=${pubkeys[@]}

for keyset in online-fish offline-fish; do
  [[ -s "keys/keysets/${TESTNET}_${keyset}" ]] || coda-network keyset create --count ${COMMUNITY_SIZE} --name "${TESTNET}_${keyset}"
done

if [[ -s "keys/testnet-keys/${TESTNET}_online-community" ]]; then
echo "using existing community keys"
else
  # Set up community keyset of the same length as the fish sets
  cat keys/keysets/${TESTNET}_online-fish | sed 's/"publicKey":"[^"]*"/"publicKey":"PLACEHOLDER"/g' > keys/keysets/${TESTNET}_online-community
fi

# Replace the community keys with the ones from community-keys.txt
for key in $PUBKEYS; do
  sed -i "s/PLACEHOLDER/$key/" keys/keysets/${TESTNET}_online-community
done
echo "Online Community Keyset:"
cat keys/keysets/${TESTNET}_online-community
echo

# SERVICES
[[ -s "keys/keysets/${TESTNET}_online-service-keys" ]] || coda-network keyset create --count 2 --name ${TESTNET}_online-service-keys

# GENESIS
if [[ -s "terraform/testnets/${TESTNET}/genesis_ledger.json" ]] ; then
  echo "-- genesis_ledger.json already exists for this testnet, refusing to overwrite. Delete \'terraform/testnets/${TESTNET}/genesis_ledger.json\' to force re-creation."
else
  echo "-- Generated the following keypairs and keysets for use in ./bin/coda-network genesis --"
  ls -R ./keys

  echo "ENTER THE FOLLOWING AT THE PROMPTS IN ORDER:"

cat <<KEYSETS
${TESTNET}_offline-fish
60000
${TESTNET}_online-community
y
${TESTNET}_online-community
5000
${TESTNET}_online-community
y
${TESTNET}_offline-whales
66900
${TESTNET}_online-whales
y
${TESTNET}_online-service-keys
50000
${TESTNET}_online-service-keys
n
KEYSETS

  coda-network genesis

  # Fix the ledger format for ease of use
  echo "Rewriting ./keys/genesis/* as terraform/testnets/${TESTNET}/genesis_ledger.json in the proper format for daemon consumption..."
  cat ./keys/genesis/* | jq '[.[] | . + { sk: null, delegate: .delegate, balance: (.balance + ".000000000") }]' | cat > terraform/testnets/${TESTNET}/genesis_ledger.json
fi

echo "Keys and genesis ledger generated successfully, $TESTNET is ready to deploy!"
