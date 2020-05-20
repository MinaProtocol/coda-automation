let Input/Images = ./Images.dhall
let Input/Network = ./Network.dhall
let Input/Secrets = ./Secrets.dhall
let BlockProducer = ../BlockProducer.dhall
in {
  images: Input/Images,
  network: Input/Network,
  secrets: Input/Secrets,
  blockProducers: List BlockProducer.Config
}
