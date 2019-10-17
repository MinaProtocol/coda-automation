#!/bin/bash

# Entrypoint for the Coda daemon service container
# Features: 
#   - Fetches Secrets (Wallet Keys) from AWS Secrets Manager on startup 
#       - Configured via environment variable `CODA_WALLET_KEYS`
#       -  `CODA_WALLET_KEYS=testnet/keys/echo/0 testnet/keys/grumpus/0`
#   - Starts coda daemon with those secrets

CLEAR='\033[0m'
RED='\033[0;31m'

function usage() {
  if [ -n "$1" ]; then
    echo -e "${RED}👉  $1${CLEAR}\n";
  fi
  echo "Usage: $0"
  echo "  --dont-fetch-secrets           If set, don't fetch secrets from AWS Secrets Manager. Default: False"
  echo "  --dont-run-daemon              If set, don't run the daemon. Default: False"
  echo ""
  echo "Example: $0"
  exit 1
}

while [[ "$#" -gt 0 ]]; do case $1 in
  --dont-fetch-secrets) NOFETCH=1; shift;;
  --dont-run-daemon) NODAEMON=1; shift;;
  -c|--command) COMMAND="$2"; shift;;
  *) echo "Unknown parameter passed: $1"; exit 1;;
esac; shift; done

# Load CODA_WALLET_KEYS array from environment
keys=($CODA_WALLET_KEYS)
key_files=()
# For each Secrets Manager key
for key in "${keys[@]}"
do
    aws --version
    # Retrieve the secret value
    secret_json="$(aws secretsmanager get-secret-value --secret-id $key | jq '.SecretString | fromjson')"
    pk="$(echo $secret_json | jq -r .public_key)"
    sk="$(echo $secret_json | jq -r .secret_key)"

    # Write public key to a file
    echo "$pk" > "/wallet-keys/$pk.pub"
    # Write private key to a file
    echo "$sk" > "/wallet-keys/$pk"
    #Set permissions on private key
    chmod 600 "/wallet-keys/$pk"
    
    key_files+=( "/wallet-keys/$pk" )
done
# Run Coda Daemon

# Gross Hack Alert
# Need to unsafely import the private keys
for file in "${key_files[@]}"
do
  coda advanced unsafe-import -privkey-path $file
done

coda daemon -peer $DAEMON_PEER -rest-port $DAEMON_REST_PORT -external-port $DAEMON_EXTERNAL_PORT -metrics-port $DAEMON_METRICS_PORT