let ofList : forall(a : Type) -> List a -> Optional (List a) =
  \(a : Type) -> \(ls : List a) ->
    if Natural/isZero (List/length a ls) then
      None (List a)
    else
      Some ls

let example0 = assert : ofList Natural [1, 2] === Some [1, 2]
let example1 = assert : ofList Text ([] : List Text) === None (List Text)

in ofList
