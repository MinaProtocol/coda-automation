#! /bin/bash

# ARGS
TESTNET="${1:-turbo-pickles}"
#COMMUNITY_KEYFILE="${2:-community-keys.txt}"
COMMUNITY_ENABLED="${2:-false}"
RESET="${3:-false}"


CODA_DAEMON_IMAGE="codaprotocol/coda-daemon:0.0.14-rosetta-scaffold-inversion-489d898"

WHALE_COUNT=5
FISH_COUNT=1

PATH=$PATH:./bin/

SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
cd "${SCRIPTPATH}/../"

if $RESET; then
  echo "resetting keys and genesis_ledger"
  ls keys/keysets/* | grep -v "bots" | xargs -I % rm "%"
  rm -rf keys/genesis keys/keypairs keys/testnet-keys
  rm -rf terraform/testnets/${TESTNET}/*.json
fi

# DIRS
mkdir -p ./keys/keysets
mkdir -p ./keys/keypairs
rm -rf ./keys/genesis && mkdir ./keys/genesis

set -eo pipefail
set -e

privkey_pass="naughty blue worm"

function generate_key_files {

  COUNT=$1
  name_prefix=$2
  output_dir="$3"
  mkdir -p $output_dir

  for k in $(seq 1 $COUNT); do
    docker run \
      --mount type=bind,source=${output_dir},target=/keys \
      --entrypoint /bin/bash $CODA_DAEMON_IMAGE \
      -c "CODA_PRIVKEY_PASS='${privkey_pass}' coda advanced generate-keypair -privkey-path /keys/${name_prefix}_${k}"
  done
}

function build_keyset_from_testnet_keys {
  output_dir=$1
  keyset_name=$2

  for file in $output_dir/*.pub; do
    nickname=$(basename $file .pub)
    jq -n ".publicKey = \"$(cat $file)\" | .nickname = \"$nickname\""
  done | jq -n ".name = \"${TESTNET}_${keyset_name}\" | .entries |= [inputs]" > keys/keysets/${TESTNET}_${keyset_name}
}

# ================================================================================

if [[ -s "keys/testnet-keys/${TESTNET}_online-whale-keyfiles/online_whale_account_1.pub" ]]; then
echo "using existing whale keys"
else
  online_output_dir="$(pwd)/keys/testnet-keys/${TESTNET}_online-whale-keyfiles"
  offline_output_dir="$(pwd)/keys/testnet-keys/${TESTNET}_offline-whale-keyfiles"

  generate_key_files $WHALE_COUNT "online_whale_account" $online_output_dir
  generate_key_files $WHALE_COUNT "offline_whale_account" $offline_output_dir

  sleep 5 #previous scripts may not be waiting for all keys, for loop misses last key sometimes
  build_keyset_from_testnet_keys $online_output_dir "online-whales"
  build_keyset_from_testnet_keys $offline_output_dir "offline-whales"

fi

echo "Online Whale Keyset:"
cat "keys/keysets/${TESTNET}_online-whales"
echo "Offline Whale Keyset:"
cat "keys/keysets/${TESTNET}_offline-whales"
echo

if [[ -s "keys/testnet-keys/${TESTNET}_online-fish-keyfiles/online_fish_account_1.pub" ]]; then
echo "using existing fish keys"
else
  online_output_dir="$(pwd)/keys/testnet-keys/${TESTNET}_online-fish-keyfiles"
  offline_output_dir="$(pwd)/keys/testnet-keys/${TESTNET}_offline-fish-keyfiles"

  generate_key_files $FISH_COUNT "online_fish_account" $online_output_dir
  generate_key_files $FISH_COUNT "offline_fish_account" $offline_output_dir

  sleep 5 #previous scripts may not be waiting for all keys, for loop misses last key sometimes
  build_keyset_from_testnet_keys $online_output_dir "online-fish"
  build_keyset_from_testnet_keys $offline_output_dir "offline-fish"
fi
echo "Online Fish Keyset:"
cat keys/keysets/${TESTNET}_online-fish
echo "Offline Fish Keyset:"
cat keys/keysets/${TESTNET}_offline-fish
echo

# ================================================================================

# ================================================================================

EXTRA_COUNT=400
# EXTRA FISH
if [[ -s "keys/testnet-keys/${TESTNET}_extra-fish-keyfiles/online_fish_account_1.pub" ]]; then
echo "using existing fish keys"
else
  output_dir="$(pwd)/keys/testnet-keys/${TESTNET}_extra-fish-keyfiles"
  generate_key_files $EXTRA_COUNT "extra_fish_account" $output_dir

  sleep 5 #previous scripts may not be waiting for all keys, for loop misses last key sometimes
  build_keyset_from_testnet_keys $output_dir "extra-fish"
fi

echo "Extra Fish Keyset:"
cat keys/keysets/${TESTNET}_extra-fish
echo

# ================================================================================

if $COMMUNITY_ENABLED; then

  # COMMUNITY 1
  declare -a PUBKEYS
  read -ra PUBKEYS <<< $(tr '\n' ' ' < community-keys-1.txt)
  COMMUNITY_SIZE=${#PUBKEYS[@]}
  echo "Generating $COMMUNITY_SIZE community keys..."

  for keyset in online-community; do
    [[ -s "keys/keysets/${TESTNET}_${keyset}" ]] || coda-network keyset create --count ${COMMUNITY_SIZE} --name "${TESTNET}_${keyset}"
  done

  if [[ -s "keys/testnet-keys/${TESTNET}_online-community" ]]; then
    echo "using existing community1 keys"
  else
    sed -ie 's/"publicKey":"[^"]*"/"publicKey":"PLACEHOLDER"/g' keys/keysets/${TESTNET}_online-community
  fi

  # Replace the community keys with the ones from community-keys.txt
  for key in ${PUBKEYS[@]}; do
    sed -ie "s/PLACEHOLDER/$key/" keys/keysets/${TESTNET}_online-community
  done
  echo "Online Community Keyset:"
  cat keys/keysets/${TESTNET}_online-community
  echo

  # COMMUNITY 2
  declare -a PUBKEYS
  read -ra PUBKEYS <<< $(tr '\n' ' ' < community-keys-2.txt)
  COMMUNITY_SIZE=${#PUBKEYS[@]}
  echo "Generating $COMMUNITY_SIZE community2 keys..."

  for keyset in online-community2; do
    [[ -s "keys/keysets/${TESTNET}_${keyset}" ]] || coda-network keyset create --count ${COMMUNITY_SIZE} --name "${TESTNET}_${keyset}"
  done

  if [[ -s "keys/testnet-keys/${TESTNET}_online-community2" ]]; then
    echo "using existing community2 keys"
  else
    sed -ie 's/"publicKey":"[^"]*"/"publicKey":"PLACEHOLDER"/g' keys/keysets/${TESTNET}_online-community2
  fi

  # Replace the community keys with the ones from community-keys.txt
  for key in ${PUBKEYS[@]}; do
    sed -ie "s/PLACEHOLDER/$key/" keys/keysets/${TESTNET}_online-community2
  done
  echo "Online Community 2 Keyset:"
  cat keys/keysets/${TESTNET}_online-community2
  echo

else
  echo "community keys disabled"
fi
# ================================================================================

  declare -a PUBKEYS
  read -ra PUBKEYS <<< $(tr '\n' ' ' < o1-keys.txt)
  COMMUNITY_SIZE=${#PUBKEYS[@]}
  echo "Generating $COMMUNITY_SIZE employee keys..."

  keyset=online-o1
  [[ -s "keys/keysets/${TESTNET}_${keyset}" ]] || coda-network keyset create --count ${COMMUNITY_SIZE} --name "${TESTNET}_${keyset}"

  if [[ -s "keys/testnet-keys/${TESTNET}_${keyset}" ]]; then
    echo "using existing ${keyset} keys"
  else
    sed -ie 's/"publicKey":"[^"]*"/"publicKey":"PLACEHOLDER"/g' keys/keysets/${TESTNET}_${keyset}
  fi

  # Replace the community keys with the ones from community-keys.txt
  for key in ${PUBKEYS[@]}; do
    sed -ie "s/PLACEHOLDER/$key/" keys/keysets/${TESTNET}_${keyset}
  done
  echo "${keyset} Keyset:"
  cat keys/keysets/${TESTNET}_${keyset}
  echo

# SERVICES
# echo "Generating 2 service keys..."
# [[ -s "keys/keysets/${TESTNET}_online-service-keys" ]] || coda-network keyset create --count 2 --name ${TESTNET}_online-service-keys

# ================================================================================

# GENESIS

if [[ -s "terraform/testnets/${TESTNET}/genesis_ledger.json" ]] ; then
  echo "-- genesis_ledger.json already exists for this testnet, refusing to overwrite. Delete \'terraform/testnets/${TESTNET}/genesis_ledger.json\' to force re-creation."
  exit
fi

#if $COMMUNITY_ENABLED ; then 
#    echo "-- Creating genesis ledger with 'coda-network genesis' --"
#else
#  echo "-- Creating genesis ledger with 'coda-network genesis' without community keys --"

PROMPT_KEYSETS="online-fish-a-4.1
66000
online-fish-a-4.1
y
online-fish-b-4.1
66001
online-fish-b-4.1
y
online-fish-c-4.1
66002
online-fish-c-4.1
y
${TESTNET}_extra-fish
66003
${TESTNET}_extra-fish
y
${TESTNET}_offline-whales
2250000
${TESTNET}_online-whales
y
${TESTNET}_offline-fish
20000
${TESTNET}_online-fish
y
${TESTNET}_online-fish
20000
${TESTNET}_online-fish
y
${TESTNET}_online-o1
20000
${TESTNET}_online-o1
y
bots
50000
bots
n
"

#fi

# Handle passing the above keyset info into interactive 'coda-network genesis' prompts
while read input
do echo "$input"
  sleep 1
done < <(echo -n "$PROMPT_KEYSETS") | coda-network genesis

GENESIS_TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Fix the ledger format for ease of use
echo "Rewriting ./keys/genesis/* as terraform/testnets/${TESTNET}/genesis_ledger.json in the proper format for daemon consumption..."
cat ./keys/genesis/* | jq '.[] | select(.balance=="2250000") | . + { sk: null, delegate: .delegate, balance: (.balance + ".000000000") }' | cat > "terraform/testnets/${TESTNET}/whales.json"
cat ./keys/genesis/* | jq '.[] | select(.balance=="20000") | . + { sk: null, delegate: .delegate, balance: (.balance + ".000000000") }' | cat > "terraform/testnets/${TESTNET}/fish.json"
cat ./keys/genesis/* | jq '.[] | select(.balance=="50000") | . + { sk: null, delegate: .delegate, balance: (.balance + ".000000000") }' | cat > "terraform/testnets/${TESTNET}/bots.json"
#if $COMMUNITY_ENABLED ; then 
  cat ./keys/genesis/* | jq '.[] | select(.balance=="66000") | . + { sk: null, delegate: .delegate, balance: (.balance + ".000000000"), timing: { initial_minimum_balance: "60000", cliff_time:"150", vesting_period:"6", vesting_increment:"150"}}' | cat > "terraform/testnets/${TESTNET}/community_fast_locked_keys.json"
  cat ./keys/genesis/* | jq '.[] | select(.balance=="66001") | . + { sk: null, delegate: .delegate, balance: (.balance + ".000000000"), timing: { initial_minimum_balance: "30000", cliff_time:"250", vesting_period:"4", vesting_increment:"200"}}' | cat > "terraform/testnets/${TESTNET}/community_slow_locked_keys.json"
  cat ./keys/genesis/* | jq '.[] | select(.balance=="66002") | . + { sk: null, delegate: .delegate, balance: (.balance + ".000000000"), timing: { initial_minimum_balance: "30000", cliff_time:"250", vesting_period:"4", vesting_increment:"200"}}' | cat > "terraform/testnets/${TESTNET}/community_slowest_locked_keys.json"
  cat ./keys/genesis/* | jq '.[] | select(.balance=="66003") | . + { sk: null, delegate: .delegate, balance: (.balance + ".000000000"), timing: { initial_minimum_balance: "30000", cliff_time:"250", vesting_period:"4", vesting_increment:"200"}}' | cat > "terraform/testnets/${TESTNET}/community_unused_keys.json"
#fi
NUM_ACCOUNTS=$(jq -s 'length'  terraform/testnets/${TESTNET}/*.json)
jq -s '{ genesis: { genesis_state_timestamp: "'${GENESIS_TIMESTAMP}'" }, ledger: { name: "'${TESTNET}'", num_accounts: '${NUM_ACCOUNTS}', accounts: [ .[] ] } }' terraform/testnets/${TESTNET}/*.json > "terraform/testnets/${TESTNET}/genesis_ledger.json"

echo "Keys and genesis ledger generated successfully, $TESTNET is ready to deploy!"
