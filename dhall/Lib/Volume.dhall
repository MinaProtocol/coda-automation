{- A lightweight wrapper that eases volume and mount configuration in kubernetes deployments -}
let K = ../External/Kubernetes.dhall

let Volume = {
  name: Text,
  readOnly: Bool
}

let default = {
  readOnly = False
}

let mount : Volume -> Text -> K.VolumeMount.Type =
  \(volume : Volume) -> \(path : Text) ->
    K.VolumeMount::{
      name = volume.name,
      readOnly = Some volume.readOnly,
      mountPath = path
    }

let kube : Volume -> K.Volume.Type =
  \(volume : Volume) ->
    K.Volume::{name = volume.name}

in {
  Type = Volume,
  default = default,
  mount = mount,
  kube = kube
}
