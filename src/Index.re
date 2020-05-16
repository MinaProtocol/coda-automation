open Cmdliner;
%raw
"process.argv.shift()";

/**
 * Keypair commands.
 */

let createKey = () => {
  open Keypair;
  let keypair = create(~nickname=None);
  print_endline("Created key: " ++ keypair->publicKeyGet);
  write(keypair);
  print_endline("Saved to disk");
};
let createKey_t = Term.(const(createKey) $ const());

/**
 * Keyset commands.
 */

let createKeyset = () => {
  open Keyset;
  let keyset = create("testset");
  upload(keyset);
  ();
};
let createKeyset_t = Term.(const(createKeyset) $ const());

/**
 * Usage command.
 */

let usage = () => print_endline("Please provide a COMMAND");
let usage_t = Term.(const(usage) $ const());

let commands = [
  (createKey_t, Term.info("keypair")),
  (createKeyset_t, Term.info("keyset")),
];

let () =
  Term.exit @@ Term.eval_choice((usage_t, Term.info("usage")), commands);
