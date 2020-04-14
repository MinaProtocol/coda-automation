{- Optional/ofMap takes a map containing optional values, and returns an
   optional map instead, lifting the optional values from inside the map.
   This effectively means that if all of the values in the map are none,
   the result will be none, and if not, returns some map without options
   where the none key-value pairs have been filtered out. -}

let Prelude = ../../External/Prelude.dhall
let Map/filterMap = ../Map/filterMap.dhall

let ofMap
  : forall(a : Type) ->
    forall(b : Type) ->
    Prelude.Map.Type a (Optional b) ->
    Optional (Prelude.Map.Type a b)
  = \(a : Type) ->
    \(b : Type) ->
    \(map : Prelude.Map.Type a (Optional b)) ->
      let newMap =
        Map/filterMap a (Optional b) b
          (Prelude.Function.identity (Optional b))
          map
      in
      if Prelude.List.null (Prelude.Map.Entry a b) newMap then
        None (Prelude.Map.Type a b)
      else
        Some newMap

let example0 = assert :
  let value = {x = Some 2, y = None Natural, z = Some 8}
  in ofMap Text Natural (toMap value) === Some (toMap {x = 2, z = 8})

let example1 = assert :
  let value = {x = None Natural, y = None Natural, z = None Natural}
  in ofMap Text Natural (toMap value) === None (Prelude.Map.Type Text Natural)

in ofMap
