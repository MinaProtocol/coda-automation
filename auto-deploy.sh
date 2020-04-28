#!/bin/sh

set -e

TESTNET="$1"
CLUSTER="gke_o1labs-192920_us-east1_coda-infra-east"

k() { kubectl --namespace="$TESTNET" "$@" ; }

if [ -z "$TESTNET" ]; then
  echo 'MISSING ARGUMENT'
  exit 1
fi

cd "terraform/testnets/$TESTNET"

image=$(sed -n 's|.*"\(codaprotocol/coda-daemon:[^"]*\)"|\1|p' main.tf)
echo "WAITING FOR IMAGE TO APPEAR IN DOCKER REGISTRY"
for i in $(seq 60); do
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
  --cluster "$CLUSTER" \
  --count "$(echo scripts/online_whale_keys/*.pub | wc -w)"
python3 scripts/testnet-keys.py k8s "upload-online-fish-keys" \
  --namespace "$TESTNET" \
  --cluster "$CLUSTER" \
  --count "$(echo scripts/online_fish_keys/*.pub | wc -w)"
python3 scripts/testnet-keys.py k8s "upload-service-keys" \
  --namespace "$TESTNET" \
  --cluster "$CLUSTER"
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

### Is this still necessary?
# sleep 60
# echo 'RESTARTING SNARK WORKERS'
# for id in $(k get pods | grep '^snark-worker' | cut -d' ' -f1); do
#   k exec -it "$id" kill 1
# done

echo 'DEPLOYMENT COMPLETED'
