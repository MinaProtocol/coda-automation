let Prelude = ../External/Prelude.dhall
let K = ../External/Kubernetes.dhall

let TextMapEntry = Prelude.Map.Entry Text Text
let TextMap = Prelude.Map.Type Text Text

let Config = {
  Type = {
    name: Text,
    podLabels: TextMap,
    podAnnotations: TextMap,
    podSpec: K.PodSpec.Type
  },
  default = {
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
        replicas = Some 2,
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

in {
  Config = Config,
  build = build
}
