#!/bin/bash

# Start scripting for coda daemon
# Changelog:
# gossip libp2p

# Common CLI options for all roles
CLI_COMMON="\
 -background \
 -tracing -log-json -log-level Trace \
 -client-port ${CODA_RPCPORT} \
 -external-port ${CODA_EXTPORT} \
 -config-directory /home/admin/test-coda \
 -external-ip ${EXTERNAL_IP} \
 -rest-port ${CODA_QLPORT} \
 -metrics-port ${CODA_METRICS_PORT} "

# Main start
case $CODA_ROLE in
"seed")
    CLI_ROLE="${CODA_SEEDLIST} "
    ;;
"seedjoiner")
    CLI_ROLE="${CODA_SEEDLIST} "
    ;;
"snarkcoordinator")
    export OMP_NUM_THREADS=4
    CLI_ROLE="${CODA_SEEDLIST} \
    -run-snark-worker ${PUBLIC_KEY} \
    -snark-worker-fee 2 \
    -work-selection seq "
    ;;
"blockproducer")
    CLI_ROLE="${CODA_SEEDLIST} \
    -propose-key /home/admin/wallet-keys/proposerkey "
    ;;
"archive")
    CLI_ROLE="${CODA_SEEDLIST} \
    -archive "
    ;;
*)
    echo "Uknown CODA_ROLE ${CODA_ROLE}"
    exit
esac

DISCOVERY_KEYFILE="/home/admin/discovery_keys/discovery_key"
if [[ -f $DISCOVERY_KEYFILE ]]; then
    echo 'Using stored libp2p discovery key'
    CLI_ROLE+=" -discovery-keypair discovery_keys/discovery_key"
    export CODA_LIBP2P_PASS='testnet'
fi

echo "Starting coda ${CODA_ROLE}"
CMD="coda daemon ${CLI_COMMON} ${CLI_ROLE}"
echo "Running: ${CMD}"

if [ "$DRYRUN" = false ]; then
    ${CMD}
else
    echo "NO-OP: DryRun"
fi
