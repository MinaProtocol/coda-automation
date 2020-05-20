let Prelude = ../External/Prelude.dhall
let K = ../External/Kubernetes.dhall

let Constants = ../Lib/Constants.dhall
let Env = ../Lib/Env.dhall
let Volume = ../Lib/Volume.dhall
let Containers/Base = ./Base.dhall

let Config = {
  Type = {
    image : Text,
    externalPort: Natural,
    seedPeers: List Text,
    codaConfigVolume: Volume.Type,
    privateKeyPassword: Text,
    blockProducerKey: Optional Text,
    snarkWorkerKey: Optional Text,
    volumeMounts: List K.VolumeMount.Type,
    memoryLimit: Text,
    memoryRequest: Text,
    cpuRequest: Double
  },
  default = {
    blockProducerKey = None Text,
    snarkWorkerKey = None Text,
    memoryLimit = "6.0Gi",
    memoryRequest = "2.0Gi",
    cpuRequest = 1.0,
    volumeMounts = ([] : List K.VolumeMount.Type)
  }
}

let Ports = {
  client: Natural,
  rest: Natural,
  metrics: Natural,
  external: Natural
}

let buildPorts : Config.Type -> Ports =
  \(conf : Config.Type) ->
    {
      client = 8301,
      rest = 3085,
      metrics = 10000,
      external = conf.externalPort
    }

let buildArgs =
  \(conf : Config.Type) -> \(ports : Ports) ->
    let baseArgs = [
      "daemon",
      "-config-directory", Constants.codaConfigPath,
      "-client-port", "${Natural/show ports.client}",
      "-rest-port", "${Natural/show ports.rest}",
      "-insecure-rest-server",
      "-metrics-port", "${Natural/show ports.metrics}",
      "-external-port", "${Natural/show ports.external}"
    ]
    let optFlag = \(flag : Text) -> \(opt : Optional Text) -> 
      Optional/fold Text opt (List Text)
        (\(value : Text) -> [flag, value])
        ([] : List Text)
    in Prelude.List.concat Text [
      baseArgs,
      optFlag "-block-producer-key" conf.blockProducerKey,
      optFlag "-snark-worker-key" conf.snarkWorkerKey
    ]

let build : Config.Type -> K.Container.Type =
  \(conf : Config.Type) ->
    let ports = buildPorts conf
    in Containers/Base.build Containers/Base.Config::{
      name = "coda",
      image = conf.image,
      command = Some ["/usr/bin/dumb-init", "/root/init_coda.sh"],
      args = Some (buildArgs conf ports),
      memoryLimit = Some conf.memoryLimit,
      memoryRequest = Some conf.memoryRequest,
      cpuRequest = Some conf.cpuRequest,
      volumeMounts = [Volume.mount conf.codaConfigVolume Constants.codaConfigPath] # conf.volumeMounts,
      env = toMap {
        DAEMON_REST_PORT = Env.Var.Constant (Natural/show ports.rest),
        DAEMON_CLIENT_PORT = Env.Var.Constant (Natural/show ports.client),
        DAEMON_METRICS_PORT = Env.Var.Constant (Natural/show ports.metrics),
        DAEMON_EXTERNAL_PORT = Env.Var.Constant (Natural/show ports.external),
        CODA_PRIVKEY_PASS = Env.Var.Constant conf.privateKeyPassword
      },
      ports = [
        K.ContainerPort::{
          name = Some "external",
          protocol = Some "TCP",
          containerPort = ports.external,
          hostPort = Some ports.external
        },
        K.ContainerPort::{
          name = Some "graphql",
          containerPort = 3085
        },
        K.ContainerPort::{
          name = Some "metrics",
          containerPort = 10000
        }
      ]
    }

in {Config, build}
