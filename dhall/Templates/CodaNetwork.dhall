let Prelude = ../External/Prelude.dhall
let K = ../External/Kubernetes.dhall

let Keypair = ../Lib/Keypair.dhall
let PodSidecar = ../Lib/PodSidecar.dhall
let CodaNodeRoleConfig = ../Lib/CodaNodeRoleConfig.dhall

let Contexts/CodaNode = ../Contexts/CodaNode.dhall
let Deployments/BlockProducer = ../Deployments/BlockProducer.dhall

{- Inputs -}
let testnetName : Text = env:TESTNET_NAME
let codaImage : Text = env:CODA_IMAGE
let codaVersion : Text = env:CODA_VERSION
let codaPrivkeyPass : Text = env:CODA_PRIVKEY_PASS
let seedPeers : List Text = env:CODA_SEED_PEERS
let roleConfigs : List CodaNodeRoleConfig.Type = env:ROLE_CONFIGS

{- Port Assignment -}
let PortAssignedRoleConfig = {
  port: Natural,
  roleConfig: CodaNodeRoleConfig.Type
}
let assignPorts : Natural -> List CodaNodeRoleConfig.Type -> List PortAssignedRoleConfig =
  \(basePort : Natural) -> \(configs : List CodaNodeRoleConfig.Type) ->
    let IndexedRoleConfig = {index: Natural, value: CodaNodeRoleConfig.Type}
    let mapPort = \(c : IndexedRoleConfig) -> {port = basePort + c.index, roleConfig = c.value}
    in Prelude.List.map IndexedRoleConfig PortAssignedRoleConfig mapPort (List/indexed CodaNodeRoleConfig.Type configs)

{- Resource Fabrication -}
let buildBlockProducerDeployment : Natural -> CodaNodeRoleConfig.BlockProducerConfig -> K.Deployment.Type =
  \(port : Natural) -> \(config : CodaNodeRoleConfig.BlockProducerConfig) ->
    Deployments/BlockProducer.build Deployments/BlockProducer.Config::{
      testnetName,
      codaImage,
      codaVersion,
      seedPeers,
      privateKeyPassword = codaPrivkeyPass,
      class = config.class,
      id = config.id,
      externalPort = port,
      keypair = config.keypair,
      podSidecarSpecs = config.podSidecarSpecs
    }
let buildSnarkWorkerDeployment : Natural -> CodaNodeRoleConfig.SnarkWorkerConfig -> K.Deployment.Type =
  \(port : Natural) -> \(config : CodaNodeRoleConfig.SnarkWorkerConfig) ->
    {- TODO: snark worker config -}
    Deployments/BlockProducer.build Deployments/BlockProducer.Config::{
      testnetName,
      codaImage,
      codaVersion,
      seedPeers,
      privateKeyPassword = codaPrivkeyPass,
      class = "TODO",
      id = 0,
      externalPort = port,
      keypair = config.keypair,
      podSidecarSpecs = ([] : List (PodSidecar.Spec Contexts/CodaNode))
    }
let buildRoleDeployment : PortAssignedRoleConfig -> K.Deployment.Type =
  \(conf : PortAssignedRoleConfig) ->
    let handlers = {
      BlockProducer = buildBlockProducerDeployment conf.port,
      SnarkWorker = buildSnarkWorkerDeployment conf.port
    }
    in merge handlers conf.roleConfig 

{- Output -}
in Prelude.List.map PortAssignedRoleConfig K.Deployment.Type buildRoleDeployment (assignPorts 10006 roleConfigs)
