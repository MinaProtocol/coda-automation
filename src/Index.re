open Cmdliner;
%raw
"process.argv.shift()";

let createKey = () =>
  print_endline(
    "Created key: " ++ Key.(create(~nickname=None)->publicKeyGet),
  );
let createKey_t = Term.(const(createKey) $ const());

let usage = () => print_endline("Please provide a COMMAND");
let usage_t = Term.(const(usage) $ const());

let createKeyset = () => {
  Keyset.(create("testset") |> write);
  ();
};
let createKeyset_t = Term.(const(createKeyset) $ const());

let commands = [
  (createKey_t, Term.info("keypair")),
  (createKeyset_t, Term.info("keyset")),
];

let () =
  Term.exit @@ Term.eval_choice((usage_t, Term.info("usage")), commands);
