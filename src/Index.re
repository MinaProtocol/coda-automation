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
      print_endline(keypair->publicKeyGet);
      write(keypair);
    | Some(message) =>
      print_endline("Unsupported action: " ++ message);
      print_endline("See --help");
    | _ => print_endline("Please provide an ACTION. See --help.")
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

let keyset = (action, keysetName) => {
  open Keyset;
  switch (action, keysetName) {
  | (Some("create"), Some(name)) =>
    let keyset = create(name);
    write(keyset);
    print_endline("Created keyset: " ++ name);
  | (Some("create"), None) =>
    print_endline("Please provide a name for the keyset with -n/--name");
  | (Some("ls"), _)
  | (Some("list"), _) =>
    Js.log(list());
  | (Some("upload"), Some(name)) =>
    let keyset = load(name);
    switch (keyset) {
    | Some(keyset) =>
      upload(keyset);
      print_endline("Uploaded keyset: " ++ name);
    | None => print_endline("The provided keyset does not exist.")
    };
  | (_, _) => print_endline("Unsupported ACTION.")
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
  (
    Term.(const(keyset) $ action $ keysetName),
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

let () = Term.exit @@ Term.eval_choice(defaultCommand, commands);
