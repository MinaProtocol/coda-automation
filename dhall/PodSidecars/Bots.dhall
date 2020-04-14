let K = ../External/Kubernetes.dhall

let Env = ../Lib/Env.dhall
let PodSidecar = ../Lib/PodSidecar.dhall
let Volume = ../Lib/Volume.dhall

let Containers/Base = ../Containers/Base.dhall
let Containers/Bash = ../Containers/Bash.dhall
let Containers/CodaKeyImport = ../Containers/CodaKeyImport.dhall
let Contexts/CodaNode = ../Contexts/CodaNode.dhall

let Config = {
  Type = {
    image: Text,
    discordApiKeyEnvVar: Env.Var,
    echoPublicKeyEnvVar: Env.Var,
    echoPrivateKeyPassword: Text,
    faucetPublicKeyEnvVar: Env.Var,
    faucetPrivateKeyPassword: Text,
    faucetAmount: Natural,
    faucetFee: Natural
  },
  default = {=}
}

let serviceKeyVolume = \(name : Text) ->
  Volume::{
    name = name,
    source = Volume.Source.Secret K.SecretVolumeSource::{
      secretName = Some name,
      defaultMode = Some 256,
      items = Some [
        K.KeyToPath::{key = "key", path = "key"},
        K.KeyToPath::{key = "pub", path = "key.pub"}
      ]
    }
  }

let importKeyContainer =
  \(context : Contexts/CodaNode) -> \(keyVolume : Volume.Type) -> \(privateKeyPassword : Text) ->
    Containers/CodaKeyImport.build Containers/CodaKeyImport.Config::{
      name = "import-${keyVolume.name}",
      codaImage = context.images.coda,
      codaConfigVolume = context.volumes.codaConfig,
      keyVolume,
      keyName = "key",
      privateKeyPassword
    }

let buildSpec : Config.Type -> PodSidecar.Spec Contexts/CodaNode =
  \(conf : Config.Type) -> \(context : Contexts/CodaNode) ->
    let echoServiceKeyVolume = serviceKeyVolume "echo-service-key"
    let faucetServiceKeyVolume = serviceKeyVolume "faucet-service-key"
    in PodSidecar::{
      volumes = [
        Volume.render echoServiceKeyVolume,
        Volume.render faucetServiceKeyVolume
      ],
      initContainers = [
        importKeyContainer context echoServiceKeyVolume conf.echoPrivateKeyPassword,
        importKeyContainer context faucetServiceKeyVolume conf.faucetPrivateKeyPassword
      ],
      containers = [
        Containers/Base.build Containers/Base.Config::{
          name = "bots",
          image = conf.image,
          memoryRequest = Some "512m",
          cpuRequest = Some 0.1,
          env = toMap {
            CODA_GRAPHQL_HOST = Env.Var.Constant "0.0.0.0",
            CODA_GRAPHQL_PORT = Env.Var.Constant "3085",
            DISCORD_API_KEY = conf.discordApiKeyEnvVar,
            ECHO_PUBLICKEY = conf.echoPublicKeyEnvVar,
            ECHO_PASSWORD = Env.Var.Constant conf.echoPrivateKeyPassword,
            FAUCET_PUBLICKEY = conf.faucetPublicKeyEnvVar,
            FAUCET_PASSWORD = Env.Var.Constant conf.faucetPrivateKeyPassword,
            FAUCET_AMOUNT = Env.Var.Constant (Natural/show conf.faucetAmount),
            FEE_AMOUNT = Env.Var.Constant (Natural/show conf.faucetFee)
          }
        }
      ]
    }

in {Config, buildSpec}
