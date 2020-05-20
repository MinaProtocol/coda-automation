{- List/filterMap is a primitive which filters values from a list and replaces
   the reamining items simultaneously. -}

let filterMap
  : forall(a : Type) ->
    forall(b : Type) ->
    (a -> Optional b) ->
    List a ->
    List b
  = \(a : Type) ->
    \(b : Type) ->
    \(f : (a -> Optional b)) ->
    \(ls : List a) ->
      let accumulateF = \(x : a) -> \(acc : List b) ->
        Optional/fold b (f x) (List b)
          (\(y : b) -> [y] # acc)
          acc
      in
      List/fold a ls (List b) accumulateF ([] : List b)

let example0 = assert :
  let result =
    filterMap Natural Natural
      (\(x : Natural) -> 
        if Natural/even x then
          Some (x * 2)
        else
          None Natural)
      [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
  in
  result === [4, 8, 12, 16, 20]

in filterMap
