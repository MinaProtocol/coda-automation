open Cmdliner;
%raw
"process.argv.shift()";

/**
 * Keypair commands.
 */

let keypair = action => {
  Keypair.(
    switch (action) {
    | Some("create") =>
      let keypair = create(~nickname=None);
      Js.log(keypair.publicKey);
      write(keypair);
    | Some(message) =>
      Js.log2("Unsupported action:", message);
      Js.log("See --help");
    | _ => Js.log("Please provide an ACTION. See --help.")
    }
  );
};
let keypairCommand = {
  let doc = "Create, upload and download keypairs.";
  let sdocs = Manpage.s_common_options;
  let action =
    Arg.(value(pos(0, some(string), None, info([], ~docv="ACTION"))));
  (Term.(const(keypair) $ action), Term.info("keypair", ~doc, ~sdocs));
};

/**
 * Keyset commands.
 */
let keyset = (action, keysetName, publicKey) => {
  open Keyset;
  switch (action, keysetName) {
  | (Some("create"), Some(name)) =>
    create(name)->write;
    Js.log("Created keyset: " ++ name);
  | (Some("create"), None)
  | (Some("add"), None) =>
    Js.log("Please provide a keyset name with -n/--name")
  | (Some("add"), Some(name)) =>
    switch (load(name), publicKey) {
    | (Some(keyset), Some(publicKey)) =>
      append(keyset, ~publicKey, ~nickname=None)->write;
      ();
    | (None, _) => Js.log("The provided keyset does not exist.")
    | (Some(_), None) =>
      Js.log("Please provide a publicKey with -k/--publickey")
    }
  | (Some("ls"), _)
  | (Some("list"), _) =>
    let _ =
      list()
      |> Js.Promise.then_(files => {
           Js.log(files);
           Js.Promise.resolve();
         });
    ();
  | (Some("upload"), Some(name)) =>
    let keyset = load(name);
    switch (keyset) {
    | Some(keyset) => upload(keyset)
    | None => Js.log("The provided keyset does not exist.")
    };
  | (_, _) => Js.log("Unsupported ACTION.")
  };
  ();
};
let keysetCommand = {
  let doc = "Generate and manage shared keysets.";
  let sdocs = Manpage.s_common_options;
  let action =
    Arg.(value(pos(0, some(string), None, info([], ~docv="ACTION"))));
  let keysetName =
    Arg.(
      value(opt(some(string), None, info(["n", "name"], ~docv="NAME")))
    );
  let publicKey =
    Arg.(
      value(
        opt(
          some(string),
          None,
          info(["k", "publicKey"], ~docv="PUBLICKEY"),
        ),
      )
    );
  (
    Term.(const(keyset) $ action $ keysetName $ publicKey),
    Term.info("keyset", ~doc, ~sdocs),
  );
};

/**
 * Default command.
 */

let defaultCommand = {
  let doc = "simple utility for spinning up coda testnets";
  let sdocs = Manpage.s_common_options;
  (
    Term.(ret(const(_ => `Help((`Pager, None))) $ const())),
    Term.info("coda-network", ~version="0.1.0-alpha", ~doc, ~sdocs),
  );
};

let commands = [keypairCommand, keysetCommand];

// Don't exit until all callbacks/Promises resolve.
let safeExit = result => {
  switch (result) {
  | `Ok(_) => ()
  | res => Term.exit(res)
  };
};

let _ = safeExit @@ Term.eval_choice(defaultCommand, commands);
