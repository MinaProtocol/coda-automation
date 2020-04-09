let K = ../External/Kubernetes.dhall

let Containers/Bash = ../Containers/Bash.dhall
let Containers/CodaNode = ../Containers/CodaNode.dhall
let Deployments/Simple = ./Simple.dhall
let Keypair = ../Lib/Keypair.dhall
let Volume = ../Lib/Volume.dhall

let Config = {
  Type = {
    testnetName: Text,
    codaVersion: Text,
    codaImage: Text,
    class: Text,
    id: Natural,
    externalPort: Natural,
    keypair: Keypair,
    privateKeyPassword: Text,
    seedPeers: List Text
  },
  default = {=}
}

let build : Config.Type -> K.Deployment.Type = 
  \(conf : Config.Type) ->
    let name = "${conf.class}-block-producer-${Natural/show conf.id}"
    let privateKeysVolume = Volume::{name = "private-keys", readOnly = True}
    let walletKeysVolume = Volume::{name = "wallet-keys", readOnly = True}
    let codaConfigVolume = Volume::{name = "coda-config"}
    in Deployments/Simple.build Deployments/Simple.Config::{
      name = name,
      podLabels = toMap {
        testnet = conf.testnetName,
        role = "block-producer",
        class = conf.class,
        version = conf.codaVersion
      },
      podAnnotations = [
        {mapKey = "prometheus.io/scrape", mapValue = "true"},
        {mapKey = "prometheus.io/path", mapValue = "/metrics"}
      ],
      {-
      podAnnotations = toMap {
        prometheus.io/scrape = "true",
        prometheus.io/path = "/metrics"
      },
      -}
      podSpec = K.PodSpec::{
        volumes = Some [
          Volume.kube privateKeysVolume,
          Volume.kube walletKeysVolume,
          Volume.kube codaConfigVolume
        ],
        initContainers = Some [
          Containers/Bash.build Containers/Bash.Config::{
            name = "fix-perms",
            command = "/bin/cp /private-keys/* /wallet-keys; /bin/chmod 0700 /wallet-keys",
            volumeMounts = [
              Volume.mount privateKeysVolume "/private-keys",
              Volume.mount walletKeysVolume "/wallet-keys"
            ],
            runAsRoot = True
          },
          Containers/Bash.build Containers/Bash.Config::{
            name = "install-keys",
            image = conf.codaImage,
            command = "coda accounts import -config-directory ${Containers/CodaNode.codaConfigPath} -privkey-path /root/wallet-keys/${conf.keypair.privateKey}",
            volumeMounts = [
              Volume.mount walletKeysVolume "/wallet-keys",
              Volume.mount codaConfigVolume Containers/CodaNode.codaConfigPath
            ],
            env = [
              K.EnvVar::{name = "CODA_PRIVKEY_PASS", value = Some conf.privateKeyPassword}
            ]
          }
        ],
        containers = [
          Containers/CodaNode.build Containers/CodaNode.Config::{
            externalPort = conf.externalPort,
            codaImage = conf.codaImage,
            codaConfigVolume = codaConfigVolume,
            volumeMounts = [Volume.mount walletKeysVolume "/wallet-keys"],
            blockProducerKey = Some "/wallet-keys/${conf.keypair.privateKey}",
            privateKeyPassword = conf.privateKeyPassword,
            seedPeers = conf.seedPeers
          }
        ]
      }
    }

in {
  Config = Config,
  build = build
}
