#! /bin/bash

# Set defaults before parsing args
TESTNET=turbo-pickles
COMMUNITY_KEYFILE=""
RESET=false

while [ $# -gt 0 ]; do
  case "$1" in
    --testnet=*)
      TESTNET="${1#*=}"
      ;;
    --community-keyfile=*)
      COMMUNITY_KEYFILE="${1#*=}"
      ;;
    --reset=*)
      RESET="${1#*=}"
      ;;
  esac
  shift
done


CODA_DAEMON_IMAGE="codaprotocol/coda-daemon:0.0.14-rosetta-scaffold-inversion-489d898"

WHALE_COUNT=5
FISH_COUNT=1


SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
cd "${SCRIPTPATH}/../"
PATH=$PATH:$(pwd)/bin

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

function generate_keyset_from_file {
  file=$1
  keyset=$2
  keys_name=$3

  declare -a PUBKEYS
  read -ra PUBKEYS <<< $(tr '\n' ' ' < ${file})
  COMMUNITY_SIZE=${#PUBKEYS[@]}
  echo "Generating $COMMUNITY_SIZE $keys_name keys..."

  if [[ -s "keys/testnet-keys/${TESTNET}_${keyset}" ]]; then
    echo "using existing ${keyset} keys"
  else

    k=1
    for key in ${PUBKEYS[@]}; do
      nickname=${TESTNET}_${keyset}${k}
      k=$(($k + 1))
      jq -n ".publicKey = \"$key\" | .nickname = \"$nickname\""
    done | jq -n ".name = \"${TESTNET}_${keyset}\" | .entries |= [inputs]" > keys/keysets/${TESTNET}_${keyset}

  fi

  echo "${keyset} Keyset:"
  cat keys/keysets/${TESTNET}_${keyset}
  echo

}
# ================================================================================

if [[ -s "keys/testnet-keys/${TESTNET}_online-whale-keyfiles/online_whale_account_1.pub" ]]; then
echo "using existing whale keys"
else
  online_output_dir="$(pwd)/keys/testnet-keys/${TESTNET}_online-whale-keyfiles"
  offline_output_dir="$(pwd)/keys/testnet-keys/${TESTNET}_offline-whale-keyfiles"

  generate_key_files $WHALE_COUNT "online_whale_account" $online_output_dir
  generate_key_files $WHALE_COUNT "offline_whale_account" $offline_output_dir

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

  build_keyset_from_testnet_keys $output_dir "extra-fish"
fi

echo "Extra Fish Keyset:"
cat keys/keysets/${TESTNET}_extra-fish
echo

# ================================================================================

if [ ! -z $COMMUNITY_KEYFILE ]; then
  generate_keyset_from_file $COMMUNITY_KEYFILE "online-community" "community"
else
  echo "community keys disabled"
fi
# ================================================================================

generate_keyset_from_file "o1-keys.txt" "online-o1" "employee"

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

PROMPT_KEYSETS=""
function add_another_to_prompt {
  from=$1
  amount=$2
  to=$3

  if [ -z $to ]; then
    to=$from
  fi

  PROMPT_KEYSETS="${PROMPT_KEYSETS}y
  ${from}
  ${amount}
  ${to}
  "
}

WHALE_AMOUNT=2250000
FISH_AMOUNT=20000
COMMUNITY_AMOUNT=66000
COMMUNITY_TIMING=${TESTNET_DIR}/
O1_AMOUNT="${FISH_AMOUNT}"

function dynamic_keysets {
  from=$1

  case $from in
    *line-fish)
      amount=${FISH_AMOUNT}
      to=${TESTNET}_online-fish
      ;;
    *line-whales)
      amount=${WHALE_AMOUNT}
      to=${TESTNET}_online-whales
      ;;
    *community*)
      amount=${COMMUNITY_AMOUNT}
      to=${2}
      ;;
    *o1)
      amount=${O1_AMOUNT}
      to=${2}
      ;;
    *)
      amount=$3
      to=$2
  esac

  if [ -z $to ]; then
    to=$from
  fi

  echo -e "y\n${from}\n${amount}\n${to}"
}


# add initial keyset
PROMPT_KEYSETS="${TESTNET}_extra-fish
66003
${TESTNET}_extra-fish
"
add_another_to_prompt ${TESTNET}_offline-whales 2250000 ${TESTNET}_online-whales
add_another_to_prompt ${TESTNET}_offline-fish 2250000 ${TESTNET}_online-fish
add_another_to_prompt ${TESTNET}_online-fish 2250000 ${TESTNET}_online-fish
add_another_to_prompt ${TESTNET}_o1 2250000 ${TESTNET}_o1

if [ -f keys/keysets/bots ];
then
  add_another_to_prompt bots 50000 bots
else
  echo "Bots keyset is missing, building ledger without them"
fi

# set not another keyset
PROMPT_KEYSETS="${PROMPT_KEYSETS}n
"

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
