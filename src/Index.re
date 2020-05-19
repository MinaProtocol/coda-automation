open Cmdliner;
%raw
"process.argv.shift()";

/**
 * Keypair commands.
 */

let createKey = () => {
  open Keypair;
  let keypair = create(~nickname=None);
  print_endline(keypair->publicKeyGet);
  write(keypair);
};
let keypairCommand = {
  let doc = "Create, upload and download keypairs.";
  let sdocs = Manpage.s_common_options;
  (Term.(const(createKey) $ const()), Term.info("keypair", ~doc, ~sdocs));
};

/**
 * Keyset commands.
 */

let createKeyset = () => {
  open Keyset;
  let keyset = create("testset");
  write(keyset);
  ();
};
let keysetCommand = {
  let doc = "Generate and manage shared keysets.";
  let sdocs = Manpage.s_common_options;
  (Term.(const(createKeyset) $ const()), Term.info("keyset", ~doc, ~sdocs));
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
