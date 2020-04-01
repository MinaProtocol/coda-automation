#!/bin/sh

set -e

TESTNET="$1"
CLUSTER="gke_o1labs-192920_us-east1_coda-infra-east"
FISH_KEYS_COUNT=200

k() { kubectl --namespace="$TESTNET" "$@" ; }

if [ -z "$TESTNET" ]; then
  echo 'MISSING ARGUMENT'
  exit 1
fi

cd "terraform/testnets/$TESTNET"

image=$(sed -n 's|.*"\(codaprotocol/coda-daemon:[^"]*\)"|\1|p' main.tf)
echo "WAITING FOR IMAGE TO APPEAR IN DOCKER REGISTRY"
for i in $(seq 30); do 
  docker pull "$image" && break
  [ "$i" != 30 ] || (echo "expected image never appeared in docker registry" && exit 1)
  sleep 60
done

echo 'RUNNING TERRAFORM'
terraform destroy -auto-approve
terraform apply -auto-approve

cd -

echo 'UPLOADING KEYS'
python3 scripts/testnet-keys.py k8s "upload-online-whale-keys" \
  --namespace "$TESTNET" \
  --cluster "$CLUSTER"
python3 scripts/testnet-keys.py k8s "upload-online-fish-keys" \
  --namespace "$TESTNET" \
  --cluster "$CLUSTER" \
  --count "$FISH_KEYS_COUNT"

sleep 60
echo 'RESTARTING SNARK WORKERS'
for id in $(k get pods | grep '^snark-worker' | cut -d' ' -f1); do
  k exec -it "$id" kill 1
done
