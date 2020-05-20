let K = ../External/Kubernetes.dhall

let Env = ../Lib/Env.dhall
let Keypair = ../Lib/Keypair.dhall
let Volume = ../Lib/Volume.dhall
let PodSidecar = ../Lib/PodSidecar.dhall

let Containers/Bash = ../Containers/Bash.dhall
let Containers/CodaKeyImport = ../Containers/CodaKeyImport.dhall
let Containers/CodaNode = ../Containers/CodaNode.dhall
let Contexts/CodaNode = ../Contexts/CodaNode.dhall
let Deployments/Simple = ./Simple.dhall

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
    seedPeers: List Text,
    podSidecarSpecs: List (PodSidecar.Spec Contexts/CodaNode)
  },
  default = {
    podSidecarSpecs = ([] : List (PodSidecar.Spec Contexts/CodaNode))
  }
}

let build : Config.Type -> K.Deployment.Type = 
  \(conf : Config.Type) ->
    let name = "${conf.class}-block-producer-${Natural/show conf.id}"

    {- volumes -}
    let privateKeysVolume = Volume::{
      name = "private-keys",
      source = Volume.Source.Secret K.SecretVolumeSource::{
        secretName = Some "online-fish-account-1-key",
        defaultMode = Some 256,
        items = Some [
          K.KeyToPath::{key = "key", path = "key"},
          K.KeyToPath::{key = "pub", path = "key.pub"}
        ]
      },
      readOnly = True
    }
    let walletKeysVolume = Volume::{
      name = "wallet-keys",
      source = Volume.Source.Empty
    }
    let codaConfigVolume = Volume::{
      name = "config-dir",
      source = Volume.Source.Empty
    }

    {- pod spec for the coda node -}
    let nodePodSpec = 
      K.PodSpec::{
        volumes = Some [
          Volume.render privateKeysVolume,
          Volume.render walletKeysVolume,
          Volume.render codaConfigVolume
        ],
        initContainers = Some [
          Containers/CodaKeyImport.build Containers/CodaKeyImport.Config::{
            name = "install-block-producer-key",
            codaImage = conf.codaImage,
            codaConfigVolume = codaConfigVolume,
            keyVolume = privateKeysVolume,
            keyName = "key",
            privateKeyPassword = conf.privateKeyPassword
          }
        ],
        containers = [
          Containers/CodaNode.build Containers/CodaNode.Config::{
            externalPort = conf.externalPort,
            image = conf.codaImage,
            codaConfigVolume = codaConfigVolume,
            volumeMounts = [Volume.mount walletKeysVolume "/wallet-keys"],
            blockProducerKey = Some "/wallet-keys/${conf.keypair.privateKey}",
            privateKeyPassword = conf.privateKeyPassword,
            seedPeers = conf.seedPeers
          }
        ]
      }

    {- contextualize and inject sidecars -}
    let context : Contexts/CodaNode = {
      images = {
        coda = conf.codaImage
      },
      volumes = {
        codaConfig = codaConfigVolume
      }
    }
    let podSidecars = PodSidecar.contextualize Contexts/CodaNode context conf.podSidecarSpecs
    let fullPodSpec = PodSidecar.inject podSidecars nodePodSpec

    {- build the deployment -}
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
      podSpec = fullPodSpec
    }

in {Config, build}
