let K = ../External/Kubernetes.dhall

let Env = ../Lib/Env.dhall
let PodSidecar = ../Lib/PodSidecar.dhall
let Containers/Python = ../Containers/Python.dhall

let Config = {
  Type = {
    image: Text,
    sendTransactionIntervalMinutes: Natural,
    publicKeyEnvVar: Env.Var,
    privateKeyPassword: Text
  },
  default = {=}
}

{- this sidecar is context free, so the spec builder is polymorphic over context -}
let buildSpec = \(a : Type) -> \(conf : Config.Type) -> \(_context : a) ->
  PodSidecar::{
    containers = [
      Containers/Python.build Containers/Python.Config::{
        name = "user-agent", 
        image = conf.image,
        pythonScript = "agent.py",
        cpuRequest = Some 0.1,
        ports = [
          K.ContainerPort::{
            name = Some "metrics",
            containerPort = 8000
          }
        ],
        env = toMap {
          AGENT_SEND_EVERY_MINUTES = Env.Var.Constant (Natural/show conf.sendTransactionIntervalMinutes),
          CODA_PUBLIC_KEY = conf.publicKeyEnvVar,
          CODA_PRIVKEY_PASS = Env.Var.Constant conf.privateKeyPassword
        }
      }
    ]
  }

in {Config, buildSpec}
