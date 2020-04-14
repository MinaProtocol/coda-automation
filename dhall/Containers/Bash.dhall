let Prelude = ../External/Prelude.dhall
let K = ../External/Kubernetes.dhall

let Env = ../Lib/Env.dhall
let Containers/Base = ./Base.dhall

let Config = {
  Type = Containers/Base.CommandlessConfig.Type //\\ {
    command: Text,
    runAsRoot: Bool
  },
  default = Containers/Base.CommandlessConfig.default /\ {
    image = "busybox",
    runAsRoot = False
  }
}

let build = \(conf : Config.Type) ->
  let insecureContext = K.SecurityContext::{runAsUser = Some 0}
  let securityContext =
    if conf.runAsRoot then
      let baseSecurityContext =
        Prelude.Optional.default K.SecurityContext.Type
          K.SecurityContext::{=}
          conf.securityContext
      in
      Some (baseSecurityContext // insecureContext)
    else
      conf.securityContext
  let baseConf = conf // {
    command = Some ["bash"],
    args = Some ["-c", conf.command],
    securityContext
  }
  in Containers/Base.build baseConf.(Containers/Base.Config.Type)

in {Config, build}
