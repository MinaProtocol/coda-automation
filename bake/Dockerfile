ARG BAKE_VERSION

FROM codaprotocol/coda-daemon:${BAKE_VERSION}

ARG COMMIT_HASH=master
ARG TESTNET_NAME=pickles-public
ARG CONFIG_FILE="/root/daemon.json"

RUN curl https://raw.githubusercontent.com/MinaProtocol/coda-automation/${COMMIT_HASH}/terraform/testnets/${TESTNET_NAME}/genesis_ledger.json -o "${CONFIG_FILE}"

RUN head ${CONFIG_FILE}

RUN coda daemon -config-file ${CONFIG_FILE} -generate-genesis-proof true; \
  mv ~/.coda-config/genesis/genesis_* /var/lib/coda/

RUN curl https://raw.githubusercontent.com/MinaProtocol/coda-automation/${COMMIT_HASH}/terraform/testnets/${TESTNET_NAME}/peers.txt -o /root/peers.txt
