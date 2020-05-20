{- A lightweight wrapper that eases volume and mount configuration in kubernetes deployments -}
let K = ../External/Kubernetes.dhall

let Source = <Empty | Secret: K.SecretVolumeSource.Type>

let Volume = {
  name: Text,
  readOnly: Bool,
  source: Source
}

let default = {
  readOnly = False
}

let mount = \(volume : Volume) -> \(path : Text) ->
  K.VolumeMount::{
    name = volume.name,
    readOnly = Some volume.readOnly,
    mountPath = path
  }

let render = \(volume : Volume) ->
  let base = {name = volume.name}
  let handlers = {
    Empty = K.Volume::(base /\ {emptyDir = Some K.EmptyDirVolumeSource.default}),
    Secret = \(secret : K.SecretVolumeSource.Type) -> K.Volume::(base /\ {secret = Some secret})
  }
  in merge handlers volume.source

in {
  Source,
  Type = Volume,
  default,
  mount,
  render
}
