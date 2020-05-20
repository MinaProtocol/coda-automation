let Prelude = ../../../dhall/External/Prelude.dhall
let Env = ../../../dhall/Lib/Env.dhall
let Keypair = ../../../dhall/Lib/Keypair.dhall
let List/filterMap = ../../../dhall/Lib/List/filterMap.dhall
let PodSidecar = ../../../dhall/Lib/PodSidecar.dhall
let Contexts/CodaNode = ../../../dhall/Contexts/CodaNode.dhall
let PodSidecars/Bots = ../../../dhall/PodSidecars/Bots.dhall
let PodSidecars/UserAgent = ../../../dhall/PodSidecars/UserAgent.dhall

let Input/Images = ./Input/Images.dhall
let Input/Secrets = ./Input/Secrets.dhall

let Class/Type = < Fish | Whale >
let Class/show = \(class : Class/Type) -> merge { Fish = "fish", Whale = "whale"} class
let Class = {
  Type = Class/Type,
  show = Class/show
}

-- TODO: Points
let SidecarId/Type = < UserAgent | Bots >
let SidecarId/toSpec : Input/Images -> Input/Secrets -> SidecarId/Type -> PodSidecar.Spec Contexts/CodaNode =
  \(images : Input/Images) ->
  \(secrets : Input/Secrets) ->
  \(sidecarId : SidecarId/Type) ->
    let branches = {
      UserAgent =
        PodSidecars/UserAgent.buildSpec Contexts/CodaNode PodSidecars/UserAgent.Config::{
          image = images.userAgent,
          sendTransactionIntervalMinutes = 10,
          -- TODO: pull dynamically from master daemon container
          publicKeyEnvVar = Env.Var.Secret {name="online-fish-account-1-key", key="pub"},
          privateKeyPassword = secrets.privateKeyPassword
        },
      Bots =
        PodSidecars/Bots.buildSpec PodSidecars/Bots.Config::{
          image = images.bots,
          discordApiKeyEnvVar = Env.Var.Secret {name="o1-discord-api-key", key="o1discord"},
          echoPublicKeyEnvVar = Env.Var.Secret {name="echo-service-key", key="pub"},
          echoPrivateKeyPassword = secrets.privateKeyPassword,
          faucetPublicKeyEnvVar = Env.Var.Secret {name="faucet-service-key", key="pub"},
          faucetPrivateKeyPassword = secrets.privateKeyPassword,
          faucetAmount = 10000000000,
          faucetFee = 100000000
        }
    }
    in merge branches sidecarId

let SidecarIdSet/Type = {userAgent: Bool, bots: Bool, points: Bool}
let SidecarIdSet/empty = {userAgent=False, bots=False, points=False}
let SidecarIdSet/add =
  \(id : SidecarId/Type) ->
  \(set : SidecarIdSet/Type) ->
    let branches = {
      UserAgent = (set with userAgent = True),
      Bots = (set with bots = True)
    } in merge branches id
let SidecarIdSet/ofList =
  \(list: List SidecarId/Type) ->
    List/fold SidecarId/Type list SidecarIdSet/Type SidecarIdSet/add SidecarIdSet/empty
let SidecarIdSet/toSpecs =
  \(images : Input/Images) ->
  \(secrets : Input/Secrets) ->
  \(sidecars: SidecarIdSet/Type) ->
    let Spec = PodSidecar.Spec Contexts/CodaNode in
    let optSidecar = \(included : Bool) -> \(id : SidecarId/Type) ->
      if included then
        Some (SidecarId/toSpec images secrets id)
      else
        None Spec
    let sidecarOptions = [optSidecar sidecars.userAgent SidecarId/Type.UserAgent, optSidecar sidecars.bots SidecarId/Type.Bots]
    in List/filterMap
      (Optional Spec)
      Spec
      (Prelude.Function.identity (Optional Spec))
      sidecarOptions

let SidecarId = {
  Type = SidecarId/Type,
  toSpec = SidecarId/toSpec,
  Set = {
    Type = SidecarIdSet/Type,
    empty = SidecarIdSet/empty,
    add = SidecarIdSet/add,
    ofList = SidecarIdSet/ofList,
    toSpecs = SidecarIdSet/toSpecs
  }
}

let Config = {
  class: Class.Type,
  keypair: Keypair,
  sidecars: List SidecarId.Type
}

in {Config, Class, SidecarId}
