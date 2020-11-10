ARG BAKE_VERSION
ARG COMMIT_HASH
ARG TESTNET_NAME

FROM codaprotocol/coda-daemon:${BAKE_VERSION}

ARG COMMIT_HASH
ARG TESTNET_NAME

RUN curl https://raw.githubusercontent.com/MinaProtocol/coda-automation/${COMMIT_HASH}/terraform/testnets/${TESTNET_NAME}/genesis_ledger.json -o ~/daemon.json

RUN sha256sum ~/daemon.json

RUN coda daemon -config-file ~/daemon.json -generate-genesis-proof true; \
  mv ~/.coda-config/genesis/genesis_* /var/lib/coda/

RUN curl https://raw.githubusercontent.com/MinaProtocol/coda-automation/${COMMIT_HASH}/terraform/testnets/${TESTNET_NAME}/peers.txt -o ~/peers.txt
