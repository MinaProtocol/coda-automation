let Prelude = ./External/Prelude.dhall
let K = ./External/Kubernetes.dhall

let Deployments/BlockProducer = ./Deployments/BlockProducer.dhall
let Keypair = ./Lib/Keypair.dhall
let RoleConfig = ./RoleConfig.dhall

{- Inputs -}
let testnetName : Text = env:TESTNET_NAME
let codaImage : Text = env:CODA_IMAGE
let codaVersion : Text = env:CODA_VERSION
let codaPrivkeyPass : Text = env:CODA_PRIVKEY_PASS
let roleConfigs : List RoleConfig.Type = env:ROLE_CONFIGS

{- Port Assignment -}
let PortAssignedRoleConfig = {
  port: Natural,
  roleConfig: RoleConfig.Type
}
let assignPorts : Natural -> List RoleConfig.Type -> List PortAssignedRoleConfig =
  \(basePort : Natural) -> \(configs : List RoleConfig.Type) ->
    let IndexedRoleConfig = {index: Natural, value: RoleConfig.Type}
    let mapPort = \(c : IndexedRoleConfig) -> {port = basePort + c.index, roleConfig = c.value}
    in Prelude.List.map IndexedRoleConfig PortAssignedRoleConfig mapPort (List/indexed RoleConfig.Type configs)

{- Resource Fabrication -}
let buildBlockProducerDeployment : Natural -> RoleConfig.BlockProducerConfig -> K.Deployment.Type =
  \(port : Natural) -> \(config : RoleConfig.BlockProducerConfig) ->
    Deployments/BlockProducer.build Deployments/BlockProducer.Config::{
      testnetName = testnetName,
      codaImage = codaImage,
      codaVersion = codaVersion,
      privateKeyPassword = codaPrivkeyPass,
      class = config.class,
      id = config.id,
      externalPort = port,
      keypair = config.keypair,
      seedPeers = ([] : List Text) {- TODO -}
    }
let buildSnarkWorkerDeployment : Natural -> RoleConfig.SnarkWorkerConfig -> K.Deployment.Type =
  \(port : Natural) -> \(config : RoleConfig.SnarkWorkerConfig) ->
    {- TODO: snark worker config -}
    Deployments/BlockProducer.build Deployments/BlockProducer.Config::{
      testnetName = testnetName,
      codaImage = codaImage,
      codaVersion = codaVersion,
      privateKeyPassword = codaPrivkeyPass,
      class = "TODO",
      id = 0,
      externalPort = port,
      keypair = config.keypair,
      seedPeers = ([] : List Text) {- TODO -}
    }
let buildRoleDeployment : PortAssignedRoleConfig -> K.Deployment.Type =
  \(conf : PortAssignedRoleConfig) ->
    let handlers = {
      BlockProducer = buildBlockProducerDeployment conf.port,
      SnarkWorker = buildSnarkWorkerDeployment conf.port
    }
    in merge handlers conf.roleConfig 

{- Output -}
in Prelude.List.map PortAssignedRoleConfig K.Deployment.Type buildRoleDeployment (assignPorts 13000 roleConfigs)
