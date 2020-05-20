let Keypair = ./Keypair.dhall
let PodSidecar = ./PodSidecar.dhall
let Contexts/CodaNode = ../Contexts/CodaNode.dhall

let BlockProducerConfig = {
  class: Text,
  id: Natural,
  keypair: Keypair,
  podSidecarSpecs: List (PodSidecar.Spec Contexts/CodaNode)
}

let SnarkWorkerConfig = {
  keypair: Keypair
}

let RoleConfigType = <
  BlockProducer: BlockProducerConfig
| SnarkWorker: SnarkWorkerConfig
>

in {
  Type = RoleConfigType,
  BlockProducerConfig = BlockProducerConfig,
  SnarkWorkerConfig = SnarkWorkerConfig
}
