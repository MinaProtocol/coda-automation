{- Intended to be used for init containers, this file describes a container
   which installs keys into the daemon from volumes -}

{- TODO: this file could be reworked to support a list of keys to upload,
   although it would add some complexity to the implementation -}

let Constants = ../Lib/Constants.dhall
let Env = ../Lib/Env.dhall
let Volume = ../Lib/Volume.dhall

let Containers/Bash = ./Bash.dhall

let Config = {
  Type = {
    name: Text,
    codaImage: Text,
    codaConfigVolume: Volume.Type,
    keyVolume: Volume.Type,
    keyName: Text,
    privateKeyPassword: Text
  },
  default = {=}
}

let importCommand = \(configDir : Text) -> \(privKeyPath : Text) ->
  "coda accounts import -config-directory ${configDir} -privkey-path ${privKeyPath}"

let build = \(conf : Config.Type) ->
  let privKeyPath = "/keys/${conf.keyName}"
  in Containers/Bash.build Containers/Bash.Config::{
    name = conf.name,
    image = conf.codaImage,
    command = "chmod 0700 /keys; ${importCommand Constants.codaConfigPath privKeyPath}",
    runAsRoot = True,
    env = toMap {
      CODA_PRIVKEY_PASS = Env.Var.Constant conf.privateKeyPassword
    },
    volumeMounts = [
      Volume.mount conf.codaConfigVolume Constants.codaConfigPath,
      Volume.mount conf.keyVolume "/keys"
    ]
  }

in {Config, build}
