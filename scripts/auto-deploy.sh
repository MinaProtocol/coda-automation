#!/bin/sh

set -e

TESTNET="$1"
CLUSTER="gke_o1labs-192920_us-east1_coda-infra-east"
KEYSDIR="${2:=./scripts/online-whale-keys}"

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
image=$(sed -n 's|.*"\(codaprotocol/coda-daemon:[^"]*\)"|\1|p' "$terraform_dir/main.tf")
echo "WAITING FOR IMAGE TO APPEAR IN DOCKER REGISTRY"
for i in $(seq 60); do
  # this is a hack; ideally, we wouldn't actually pull the image, just check if it's there
  docker pull "$image" && break
  [ "$i" != 30 ] || (echo "expected image never appeared in docker registry" && exit 1)
  sleep 60
done

cd $terraform_dir
echo 'RUNNING TERRAFORM'
terraform destroy -auto-approve
terraform apply -auto-approve
cd -

echo 'UPLOADING KEYS'
python3 scripts/testnet-keys.py k8s "upload-online-whale-keys" \
  --namespace "$TESTNET" \
  --cluster "$CLUSTER" \
  --key-dir "$KEYSDIR"
  
#python3 scripts/testnet-keys.py k8s "upload-online-fish-keys" \
#  --namespace "$TESTNET" \
#  --cluster "$CLUSTER" \
#  --count "$(echo scripts/online_fish_keys/*.pub | wc -w)"
#python3 scripts/testnet-keys.py k8s "upload-service-keys" \
#  --namespace "$TESTNET" \
#  --cluster "$CLUSTER"
if [ -e scripts/o1-discord-api-key ]; then
  kubectl create secret generic o1-discord-api-key \
    "--cluster=$CLUSTER" \
    "--namespace=$TESTNET" \
    "--from-file=o1discord=scripts/o1-discord-api-key"
else
  echo '*** NOT UPLOADING DISCORD API KEY (required when running with bots sidecar)'
fi
if [ -e scripts/o1-google-cloud-storage-api-key.json ]; then
  kubectl create secret generic o1-google-cloud-storage-api-key \
    "--cluster=$CLUSTER" \
    "--namespace=$TESTNET" \
    "--from-file=o1google=scripts/o1-google-cloud-storage-api-key.json"
else
  echo '*** NOT UPLOADING GOOGLE CLOUD STORAGE API KEY (required when running with points sidecar)'
fi

echo 'DEPLOYMENT COMPLETED'
