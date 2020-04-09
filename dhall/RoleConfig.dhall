let Keypair = ./Lib/Keypair.dhall

let BlockProducerConfig = {
  class: Text,
  id: Natural,
  keypair: Keypair
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
