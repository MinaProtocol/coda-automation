type entry = {
  pk: string,
  sk: option(string),
  balance: string,
  delegate: option(string),
};

type t = array(entry);

/**
 * Generates a genesis ledger from the given configuration
 */
let create: array((Keyset.t, int, option(Keyset.t))) => t =
  config => {
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
