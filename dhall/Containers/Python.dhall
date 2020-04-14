let K = ../External/Kubernetes.dhall

let Env = ../Lib/Env.dhall
let Containers/Bash = ./Bash.dhall
let Containers/Base = ./Base.dhall

let Config = {
  Type = Containers/Base.Config.Type //\\ {
    pythonScript: Text
  },
  default = Containers/Base.Config.default // {
    memoryRequest = Some "512m",
    cpuRequest = Some "0.1"
  }
}

let build =
  \(conf : Config.Type) ->
    let baseConf = conf.(Containers/Base.Config.Type)
    let bashConf = baseConf // {
      command = "python3 \"${conf.pythonScript}\"",
      runAsRoot = False,
      env = Env.extend conf.env (toMap {
        PYTHONUNBUFFERED = Env.Var.Constant "1"
      })
    }
    in Containers/Bash.build bashConf.(Containers/Bash.Config.Type)

in {Config, build}
