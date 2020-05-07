open Cmdliner;
%raw
"process.argv.shift()";

let createKey = () =>
  print_endline("Created key: " ++ Keys.create(~nickname=None).publicKey);
let createKey_t = Term.(const(createKey) $ const());

let usage = () => print_endline("Please provide a COMMAND");
let usage_t = Term.(const(usage) $ const());

let commands = [(createKey_t, Term.info("keypair"))];

let () =
  Term.exit @@ Term.eval_choice((usage_t, Term.info("usage")), commands);
