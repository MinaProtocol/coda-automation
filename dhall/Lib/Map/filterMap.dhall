let Prelude = ../../External/Prelude.dhall

let List/filterMap = ../List/filterMap.dhall

let filterMap
  : forall(key : Type) ->
    forall(a : Type) ->
    forall(b : Type) ->
    (a -> Optional b) ->
    Prelude.Map.Type key a ->
    Prelude.Map.Type key b
  = \(key : Type) ->
    \(a : Type) ->
    \(b : Type) ->
    \(f : a -> Optional b) ->
      let EntryA = Prelude.Map.Entry key a
      let EntryB = Prelude.Map.Entry key b
      in List/filterMap EntryA EntryB
        (\(entry : EntryA) ->
          Prelude.Optional.map b EntryB
            (\(value : b) -> entry // {mapValue = value})
            (f entry.mapValue))

{- TODO: tests -}

in filterMap
