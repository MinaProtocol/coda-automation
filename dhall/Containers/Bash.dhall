let Prelude = ../External/Prelude.dhall
let K = ../External/Kubernetes.dhall

let Config = {
  Type = {
    name: Text,
    image: Text,
    command: Text,
    volumeMounts: List K.VolumeMount.Type,
    runAsRoot: Bool,
    env: List K.EnvVar.Type
  },
  default = {
    image = "busybox",
    volumeMounts = Prelude.List.empty K.VolumeMount.Type,
    runAsRoot = False,
    env = Prelude.List.empty K.EnvVar.Type
  }
}

let build : Config.Type -> K.Container.Type =
  \(conf : Config.Type) ->
    let insecureContext = K.SecurityContext::{runAsUser = Some 0}
    let securityContext = if conf.runAsRoot then Some insecureContext else None K.SecurityContext.Type
    let optional = \(a : Type) -> \(ls : List a) -> if Prelude.List.null a ls then None (List a) else Some ls
    in K.Container::{
      name = conf.name,
      image = Some conf.image,
      command = Some ["bash", "-c", conf.command],
      volumeMounts = optional K.VolumeMount.Type conf.volumeMounts,
      securityContext = securityContext,
      env = optional K.EnvVar.Type conf.env
    }

in {
  Config = Config,
  build = build
}
