type entry = {
  pk: string,
  sk: option(string),
  balance: string,
  delegate: option(string),
};

type t = array(entry);
type config = (Keyset.t, int, option(Keyset.t));

/**
 * Generates a genesis ledger from the given configuration
 */
let create = config => {
  // Reduce the config into a genesis ledger array
  Array.fold_right(
    (
      (keyset, balance, delegateKeyset): (Keyset.t, int, option(Keyset.t)),
      acc,
    ) => {
      // Sanity check that delegate keyset has the same number of keys
      switch (delegateKeyset) {
      | Some(delegateKeyset) =>
        if (Array.length(keyset.entries)
            !== Array.length(delegateKeyset.entries)) {
          raise(
            Invalid_argument(
              "Delegate keyset doesn't have the same number of keys",
            ),
          );
        }
      | None => ()
      };

      Array.map(
        keysetEntry => {
          let entry: Keyset.entry = keysetEntry;
          {
            pk: entry.publicKey,
            sk: None,
            balance: string_of_int(balance),
            delegate: None,
          };
        },
        keyset.entries,
      )
      |> Array.append(acc);
    },
    config,
    [||],
  );
};

/**
 * Writes a genesis ledger to disk.
 */
let write = ledger => {
  let content = Js.Json.stringifyAny(ledger)->Belt.Option.getExn;
  Cache.write(Cache.Genesis, ~filename="version", content);
};

let promptEntry: unit => Js.Promise.t(config) =
  () => {
    Js.Promise.(
      Prompt.question("Name: ")
      |> then_(result =>
           switch (Keyset.load(result)) {
           | Some(keyset) =>
             all2((Prompt.question("Keyset balance: "), resolve(keyset)))
           | None => reject(Prompt.Invalid_input)
           }
         )
      |> then_(((balance, keyset)) =>
           switch (int_of_string_opt(balance)) {
           | Some(bal) => resolve((keyset, bal, None))
           | None => reject(Prompt.Invalid_input)
           }
         )
    );
  };

let rec prompt = config => {
  open Js.Promise;
  let count = Array.length(config);
  let title = "Keyset #" ++ string_of_int(count + 1);
  Js.log(title);
  Js.log(String.make(String.length(title), '='));
  promptEntry()
  |> then_(entry => {
       all2((
         Prompt.yesNo("Add another keyset? [y/n] "),
         resolve(Array.append(config, [|entry|])),
       ))
     })
  |> then_(((another, newConfig)) =>
       another ? prompt(newConfig) : resolve(newConfig)
     )
  |> catch(error => {
       Js.log(error);
       resolve([||]);
     });
};
