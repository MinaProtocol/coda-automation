{--- PodSidecar: an abstraction for composing additional containers into a pod spec ---}

let Prelude = ../External/Prelude.dhall
let K = ../External/Kubernetes.dhall

let PodSidecar = {
  volumes: List K.Volume.Type,
  initContainers: List K.Container.Type,
  containers: List K.Container.Type
}

let default = {
  volumes = ([] : List K.Volume.Type),
  initContainers = ([] : List K.Container.Type),
  containers = ([] : List K.Container.Type)
}

{- injects a list into an optional list; helpful for extending kube configs -}
let injectList =
  \(a : Type) ->
  \(base : Optional (List a)) ->
  \(ext : List a) ->
    if Prelude.List.null a ext then
      base
    else
      Prelude.Optional.map (List a) (List a)
        (\(ls : List a) -> ext # ls)
        base

{- injects a list of sidecars into a pod spec -}
let inject : List PodSidecar -> K.PodSpec.Type -> K.PodSpec.Type =
  \(sidecars : List PodSidecar) -> \(podSpec : K.PodSpec.Type) ->
    let mapSidecars = \(a : Type) -> \(f : PodSidecar -> List a) ->
      Prelude.List.concatMap PodSidecar a f sidecars
    let sidecarVolumes = mapSidecars K.Volume.Type (\(s : PodSidecar) -> s.volumes)
    let sidecarInitContainers = mapSidecars K.Container.Type (\(s : PodSidecar) -> s.initContainers)
    let sidecarContainers = mapSidecars K.Container.Type (\(s : PodSidecar) -> s.containers)
    in podSpec // {
      volumes = injectList K.Volume.Type podSpec.volumes sidecarVolumes,
      initContainers = injectList K.Container.Type podSpec.initContainers sidecarInitContainers,
      containers = sidecarContainers # podSpec.containers
    }

let Spec = \(Context : Type) -> (Context -> PodSidecar)

{- creates a list of sidecars from a list of specs and a context -}
let contextualize : forall(a : Type) -> a -> List (Spec a) -> List PodSidecar =
  \(a : Type) -> \(context : a) ->
    Prelude.List.map (Spec a) PodSidecar (\(spec : Spec a) -> spec context)

in {
  Type = PodSidecar,
  default,
  inject,
  Spec,
  contextualize
}
