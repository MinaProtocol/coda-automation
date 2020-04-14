let K = ../External/Kubernetes.dhall
let Prelude = ../External/Prelude.dhall

let Env = ../Lib/Env.dhall
let Optional/ofList = ../Lib/Optional/ofList.dhall
let Optional/ofMap = ../Lib/Optional/ofMap.dhall

let CommandlessConfig = {
  Type = {
    name: Text,
    image: Text,
    memoryLimit: Optional Text,
    memoryRequest: Optional Text,
    cpuRequest: Optional Double,
    env: Env.Type,
    ports: List K.ContainerPort.Type,
    volumeMounts: List K.VolumeMount.Type,
    securityContext: Optional K.SecurityContext.Type
  },
  default = {
    memoryLimit = None Text,
    memoryRequest = None Text,
    cpuRequest = None Double,
    env = Env.empty,
    ports = ([] : List K.ContainerPort.Type),
    volumeMounts = ([] : List K.VolumeMount.Type),
    securityContext = None K.SecurityContext.Type
  }
}

let Config = {
  Commandless = CommandlessConfig,
  Type = CommandlessConfig.Type //\\ {
    command: Optional (List Text),
    args: Optional (List Text)
  },
  default = CommandlessConfig.default // {
    command = None (List Text),
    args = None (List Text)
  }
}

let build = \(conf : Config.Type) ->
  K.Container::{
    name = conf.name,
    image = Some conf.image,
    imagePullPolicy = Some "Always",
    resources = Some K.ResourceRequirements::{
      limits = Optional/ofMap Text Text (toMap {
        memory = conf.memoryLimit
      }),
      requests = Optional/ofMap Text Text (toMap {
        memory = conf.memoryRequest,
        cpu = Prelude.Optional.map Double Text Double/show conf.cpuRequest
      })
    },
    volumeMounts = Optional/ofList K.VolumeMount.Type conf.volumeMounts,
    securityContext = conf.securityContext,
    command = conf.command,
    args = conf.args,
    ports = Optional/ofList K.ContainerPort.Type conf.ports,
    env = Optional/ofList K.EnvVar.Type (Env.render conf.env)
  }

in {CommandlessConfig, Config, build}
