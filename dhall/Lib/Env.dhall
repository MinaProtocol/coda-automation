let K = ../External/Kubernetes.dhall
let Prelude = ../External/Prelude.dhall

let SecretKeyRef =
  {name: Text, key: Text}

let Var = <
  Constant: Text
| Secret: SecretKeyRef
>

let Var/render : Text -> Var -> K.EnvVar.Type =
  \(name : Text) -> \(var : Var) ->
    let handlers =
      {
        Constant = \(value : Text) ->
          K.EnvVar::{
            name,
            value = Some value
          },
        Secret = \(secret : SecretKeyRef) ->
          K.EnvVar::{
            name,
            valueFrom = Some K.EnvVarSource::{
              secretKeyRef = Some K.SecretKeySelector::{
                name = Some secret.name,
                key = secret.key
              }
            }
          }
      }
    in merge handlers var

let Env = Prelude.Map.Type Text Var

let empty : Env = Prelude.Map.empty Text Var

let extend : Env -> Env -> Env =
  \(x : Env) -> \(y : Env) ->
    Prelude.List.concat (Prelude.Map.Entry Text Var)
      [x, y]

let render : Env -> List K.EnvVar.Type =
  let Entry = Prelude.Map.Entry Text Var
  in Prelude.List.map Entry K.EnvVar.Type (\(entry : Entry) ->
    Var/render entry.mapKey entry.mapValue)

{- TODO: write tests -}

in {
  SecretKeyRef,
  Var,
  Var/render,
  Type = Env,
  empty,
  extend,
  render
}
