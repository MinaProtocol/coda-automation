#!/bin/bash

set -e

TESTNET="$1"
GENERATE_KEYS="$2"
CLUSTER="${CLUSTER:-gke_o1labs-192920_us-east1_coda-infra-east}"

docker_tag_exists() {
    IMAGE=$(echo $1 | awk -F: '{ print $1 }')
    TAG=$(echo $1 | awk -F: '{ print $2 }')
    curl --silent -f -lSL https://index.docker.io/v1/repositories/$IMAGE/tags/$TAG > /dev/null
}
k() { kubectl --cluster="$CLUSTER" --namespace="$TESTNET" "$@" ; }

if [ -z "$TESTNET" ]; then
  echo 'MISSING ARGUMENT'
  exit 1
fi

[ "$(pwd)" = "$(dirname "$0")" ] && cd ..
if [ ! -d .git ]; then
  echo "INVALID DIRECTORY -- this script must be run from either the ./ or ./scripts/ (relative to the git repository)"
  exit 1
fi


terraform_dir="terraform/testnets/$TESTNET"
image=$(sed -n 's|.*"\(.*/coda-daemon:[^"]*\)"|\1|p' "$terraform_dir/main.tf")
image=$(echo "${image}" | head -1)
echo "WAITING FOR IMAGE ${image} TO APPEAR IN DOCKER REGISTRY"
#for i in $(seq 60); do
#  docker_tag_exists "$image" && break
#  [ "$i" != 30 ] || (echo "expected image never appeared in docker registry" && exit 1)
#  sleep 10
#done

if [[ -n "$2" ]] ; then
  echo 'GENERATING KEYS'
  scripts/generate-keys-and-ledger.sh "${TESTNET}" "$2" # Generates whale (10), fish (1), community (variable), and service keys (2)
fi

cd $terraform_dir
echo 'RUNNING TERRAFORM in '"$terraform_dir"
terraform init
terraform plan
read -p "Is the above terraform plan sufficient? [Y/n] " -n 1 -r
echo
[[ ! $REPLY =~ ^[Yy]$ ]] && echo "insufficient terraform plan, exiting before doing anything destructive" && exit 1 
terraform destroy -auto-approve
terraform apply -auto-approve
cd -

echo 'UPLOADING KEYS'

python3 scripts/testnet-keys.py k8s "upload-online-whale-keys" \
  --namespace "$TESTNET" \
  --cluster "$CLUSTER" \
  --key-dir "keys/testnet-keys/${TESTNET}_online-whale-keyfiles"

 python3 scripts/testnet-keys.py k8s "upload-online-fish-keys" \
  --namespace "$TESTNET" \
  --cluster "$CLUSTER" \
  --key-dir "keys/testnet-keys/${TESTNET}_online-fish-keyfiles" \

#python3 scripts/testnet-keys.py k8s "upload-service-keys" \
#  --namespace "$TESTNET" \
#  --cluster "$CLUSTER" \
#  --key-dir "keys/keysets/$TESTNET_online-service-keys"

if [ -e keys/api-keys/o1-discord-api-key ]; then
  kubectl create secret generic o1-discord-api-key \
    "--cluster=$CLUSTER" \
    "--namespace=$TESTNET" \
    "--from-file=o1discord=keys/api-keys/o1-discord-api-key"
else
  echo '*** NOT UPLOADING DISCORD API KEY (required when running with bots sidecar)'
fi

echo 'DEPLOYMENT COMPLETED'
