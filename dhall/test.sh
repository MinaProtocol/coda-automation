#!/bin/bash

export TESTNET_NAME='"not-broken"'
export CODA_IMAGE='"codaprotocol/coda-daemon:0.0.12-beta-release-0.0.13-beta-7cee1ba"'
export CODA_VERSION='"0.0.13-beta-7cee1ba"'
export CODA_PRIVKEY_PASS='"naughty blue worm"'
export CODA_SEED_PEERS='["/ip4/104.196.195.165/tcp/10001/ipfs/12D3KooWAFFq2yEQFFzhU5dt64AWqawRuomG9hL8rSmm5vxhAsgr","/ip4/35.196.112.167/tcp/10001/ipfs/12D3KooWB79AmjiywL1kMGeKHizFNQE9naThM2ooHgwFcUzt6Yt1"]'

export ROLE_CONFIGS=$(cat <<-END
  let Role = ./Lib/CodaNodeRoleConfig.dhall
  let PodSidecar = ./Lib/PodSidecar.dhall
  let Contexts/CodaNode = ./Contexts/CodaNode.dhall
  in [
    Role.Type.BlockProducer {
      class = "whale",
      id = 0,
      keypair = {publicKey="whale-keys/0.pub", privateKey="whale-keys/0"},
      podSidecarSpecs = ([] : List (PodSidecar.Spec Contexts/CodaNode))
    },
    Role.Type.BlockProducer {
      class = "whale",
      id = 1,
      keypair = {publicKey="whale-keys/1.pub", privateKey="whale-keys/1"},
      podSidecarSpecs = ([] : List (PodSidecar.Spec Contexts/CodaNode))
    }
  ]
END
)

dhall-to-yaml --quoted --documents --file Templates/CodaNetwork.dhall "$@"
