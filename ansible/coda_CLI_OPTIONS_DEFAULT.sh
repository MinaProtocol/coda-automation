#!/bin/bash

# Common CLI options for all roles
CLI_COMMON="\
 -background \
 -tracing -log-json -log-level Trace \
 -client-port ${CODA_RPCPORT} \
 -external-port ${CODA_EXTPORT} \
 -config-directory /home/admin/test-coda \
 -external-ip ${EXTERNAL_IP} \
 -rest-port ${CODA_QLPORT} \
 -metrics-port ${CODA_METRICS_PORT} \
-discovery-port ${CODA_PEERPORT} "

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

DISCOVERY_KEYFILE="/home/admin/discovery_key"
if [[ -f $DISCOVERY_KEYFILE ]]; then
    echo 'Using stored libp2p discovery key'
    DISCOVERY_KEYPAIR=$(cat $DISCOVERY_KEYFILE)
    CLI_ROLE+=" -discovery-keypair $DISCOVERY_KEYPAIR"
fi

echo "Starting coda ${CODA_ROLE}"
CMD="coda daemon ${CLI_COMMON} ${CLI_ROLE}"
echo "Running: ${CMD}"

if [ "$DRYRUN" = false ]; then
    CODA_PRIVKEY_PASS="{{ privkey_pass }}"  ${CMD}
else
    echo "NO-OP: DryRun"
fi
