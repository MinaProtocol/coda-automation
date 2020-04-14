let Prelude = ../External/Prelude.dhall
let K = ../External/Kubernetes.dhall

let TextMapEntry = Prelude.Map.Entry Text Text
let TextMap = Prelude.Map.Type Text Text

let Config = {
  Type = {
    name: Text,
    replicas: Natural,
    podLabels: TextMap,
    podAnnotations: TextMap,
    podSpec: K.PodSpec.Type
  },
  default = {
    replicas = 1,
    podAnnotations = ([] : TextMap)
  }
}

let build : Config.Type -> K.Deployment.Type =
  \(conf : Config.Type) ->
    let baseLabels = toMap {app = conf.name}
    in K.Deployment::{
      metadata = K.ObjectMeta::{
        name = conf.name,
        labels = Some baseLabels
      },
      spec = Some K.DeploymentSpec::{
        replicas = Some conf.replicas,
        selector = K.LabelSelector::{
          matchLabels = Some baseLabels
        },
        template = K.PodTemplateSpec::{
          metadata = K.ObjectMeta::{
            name = conf.name,
            labels = Some (Prelude.List.concat TextMapEntry [baseLabels, conf.podLabels]),
            annotations = Some conf.podAnnotations
          },
          spec = Some conf.podSpec
        }
      }
    }

in {Config, build}
