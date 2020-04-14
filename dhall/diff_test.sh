#!/bin/bash

set -e

# HINT: install dyff (https://github.com/homeport/dyff) and run this with DIFF="dyff between"
DIFF="${DIFF:-diff}"

export TESTNET_NAME='"bugspray"'
export CODA_IMAGE='"codaprotocol/coda-daemon:0.0.12-beta-release-0.0.13-beta-7cee1ba"'
export CODA_VERSION='"0.0.12-beta-release-0.0.13-beta-7cee1ba"'
export CODA_PRIVKEY_PASS='"naughty blue worm"'
export CODA_SEED_PEERS='["/ip4/104.196.195.165/tcp/10001/ipfs/12D3KooWAFFq2yEQFFzhU5dt64AWqawRuomG9hL8rSmm5vxhAsgr","/ip4/35.196.112.167/tcp/10001/ipfs/12D3KooWB79AmjiywL1kMGeKHizFNQE9naThM2ooHgwFcUzt6Yt1"]'

export ROLE_CONFIGS=$(cat <<-END
  let Role = ./Lib/CodaNodeRoleConfig.dhall
  let Env = ./Lib/Env.dhall
  let Contexts/CodaNode = ./Contexts/CodaNode.dhall
  let PodSidecars/UserAgent = ./PodSidecars/UserAgent.dhall
  let PodSidecars/Bots = ./PodSidecars/Bots.dhall
  in [
    Role.Type.BlockProducer {
      class = "fish",
      id = 1,
      keypair = {publicKey="fish-keys/0.pub", privateKey="fish-keys/0"},
      podSidecarSpecs = [
        PodSidecars/UserAgent.buildSpec Contexts/CodaNode PodSidecars/UserAgent.Config::{
          image = "codaprotocol/coda-user-agent:0.1.5-bugspray",
          sendTransactionIntervalMinutes = 10,
          publicKeyEnvVar = Env.Var.Secret {name="online-fish-account-1-key", key="pub"},
          privateKeyPassword = $CODA_PRIVKEY_PASS
        },
        PodSidecars/Bots.buildSpec PodSidecars/Bots.Config::{
          image = "codaprotocol/coda-bots:0.0.13-beta-1",
          discordApiKeyEnvVar = Env.Var.Secret {name="o1-discord-api-key", key="o1discord"},
          echoPublicKeyEnvVar = Env.Var.Secret {name="echo-service-key", key="pub"},
          echoPrivateKeyPassword = $CODA_PRIVKEY_PASS,
          faucetPublicKeyEnvVar = Env.Var.Secret {name="faucet-service-key", key="pub"},
          faucetPrivateKeyPassword = $CODA_PRIVKEY_PASS,
          faucetAmount = 10000000000,
          faucetFee = 100000000
        }
      ]
    }
  ]
END
)

dhall-to-yaml --documents \
  --file Templates/CodaNetwork.dhall \
  --output bugspray-fish-1.dhall.yaml \
  "$@"
$DIFF bugspray-fish-1.helm.yaml bugspray-fish-1.dhall.yaml
