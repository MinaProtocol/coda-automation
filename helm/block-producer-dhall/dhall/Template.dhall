let K = ../../../dhall/External/Kubernetes.dhall
let Prelude = ../../../dhall/External/Prelude.dhall
let Deployments/BlockProducer = ../../../dhall/Deployments/BlockProducer.dhall

let BlockProducer = ./BlockProducer.dhall
let Input = ./Input/Main.dhall

let Indexed = \(T : Type) -> {index: Natural, value: T}

let input : Input = env:INPUT

let buildBlockProducerDeployment = \(indexedConfig : Indexed BlockProducer.Config) ->
  let index = indexedConfig.index
  let config = indexedConfig.value
  let class = BlockProducer.Class.show config.class
  let podSidecarSpecs = BlockProducer.SidecarId.Set.toSpecs input.images input.secrets (BlockProducer.SidecarId.Set.ofList config.sidecars)
  in Deployments/BlockProducer.build Deployments/BlockProducer.Config::{
    testnetName = input.network.name,
    codaImage = input.images.daemon,
    codaVersion = input.network.version,
    seedPeers = input.network.seedPeers,
    privateKeyPassword = input.secrets.privateKeyPassword,
    class,
    id = index,
    -- id = "${class}-block-producer-${Natural/show index}",
    externalPort = input.network.baseExternalPort + index,
    keypair = config.keypair,
    podSidecarSpecs
  }

in Prelude.List.map (Indexed BlockProducer.Config) K.Deployment.Type
  buildBlockProducerDeployment
  (List/indexed BlockProducer.Config input.blockProducers)
