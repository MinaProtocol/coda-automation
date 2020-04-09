#!/bin/sh

export TESTNET_NAME='"not-broken"'
export CODA_IMAGE='"codaprotocol/coda-daemon:0.0.12-beta-release-0.0.13-beta-7cee1ba"'
export CODA_VERSION='"0.0.13-beta-7cee1ba"'
export CODA_PRIVKEY_PASS='"naughty blue worm"'

export ROLE_CONFIGS=$(cat <<-END
  let R = (./RoleConfig.dhall).Type
  in [
    R.BlockProducer {
      class = "whale",
      id = 0,
      keypair = {publicKey="whale-keys/0.pub", privateKey="whale-keys/0"}
    },
    R.BlockProducer {
      class = "whale",
      id = 1,
      keypair = {publicKey="whale-keys/1.pub", privateKey="whale-keys/1"}
    }
  ]
END
)

dhall-to-yaml --documents "$@" < CodaNetwork.dhall
