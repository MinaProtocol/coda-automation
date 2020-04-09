let Prelude = ../External/Prelude.dhall
let K = ../External/Kubernetes.dhall

let Volume = ../Lib/Volume.dhall

let Config = {
  Type = {
    externalPort: Natural,
    seedPeers: List Text,
    codaImage: Text,
    codaConfigVolume: Volume.Type,
    volumeMounts: List K.VolumeMount.Type,
    privateKeyPassword: Text,
    blockProducerKey: Optional Text,
    snarkWorkerKey: Optional Text,
    memoryLimit: Text,
    memoryRequest: Text,
    cpuRequest: Text
  },
  default = {
    blockProducerKey = None Text,
    snarkWorkerKey = None Text,
    memoryLimit = "6.0Gi",
    memoryRequest = "2.0Gi",
    cpuRequest = "1"
  }
}

let Ports = {
  client: Natural,
  rest: Natural,
  metrics: Natural,
  external: Natural
}

let codaConfigPath = "/root/.coda-config"

let buildPorts : Config.Type -> Ports =
  \(conf : Config.Type) ->
    {
      client = 3085,
      rest = 8301,
      metrics = 10000,
      external = conf.externalPort
    }

let buildArgs : Config.Type -> Ports -> List Text =
  \(conf : Config.Type) -> \(ports : Ports) ->
    let baseArgs = [
      "daemon",
      "-config-directory", codaConfigPath,
      "-client-port", "${Natural/show ports.client}",
      "-rest-port", "${Natural/show ports.rest}",
      "-insecure-rest-server",
      "-metrics-port", "${Natural/show ports.metrics}",
      "-external-port", "${Natural/show ports.external}"
    ]
    let optFlag = \(flag : Text) -> \(opt : Optional Text) -> 
      Optional/fold Text opt (List Text)
        (\(value : Text) -> [flag, value])
        (Prelude.List.empty Text)
    in Prelude.List.concat Text [
      baseArgs,
      optFlag "-block-producer-key" conf.blockProducerKey,
      optFlag "-snark-worker-key" conf.snarkWorkerKey
    ]

let build : Config.Type -> K.Container.Type =
  \(conf : Config.Type) ->
    let envVar = \(name : Text) -> \(value : Text) -> K.EnvVar::{name = name, value = Some value}
    let ports = buildPorts conf
    in K.Container::{
      name = "coda",
      image = Some conf.codaImage,
      imagePullPolicy = Some "Always",
      resources = Some K.ResourceRequirements::{
        limits = Some (toMap {
          memory = conf.memoryLimit
        }),
        requests = Some (toMap {
          memory = conf.memoryRequest,
          cpu = conf.cpuRequest
        })
      },
      command = Some ["/usr/bin/dumb-init", "/root/init_coda.sh"],
      args = Some (buildArgs conf ports),
      env = Some [
        envVar "DAEMON_REST_PORT" (Natural/show ports.rest),
        envVar "DAEMON_CLIENT_PORT" (Natural/show ports.client),
        envVar "DAEMON_METRICS_PORT" (Natural/show ports.metrics),
        envVar "DAEMON_EXTERNAL_PORT" (Natural/show ports.external),
        envVar "CODA_PRIVKEY_PASS" conf.privateKeyPassword
      ],
      ports = Some [
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
      ],
      volumeMounts = Some ([Volume.mount conf.codaConfigVolume codaConfigPath] # conf.volumeMounts)
    }

in {
  Config = Config,
  build = build,
  codaConfigPath = codaConfigPath
}
