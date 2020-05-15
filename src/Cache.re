type model =
  | Keypair
  | Keyset;

// TODO: Add support for ENV and non Unix environments
let baseDir = "/usr/local/var/coda-network";
let keypairsDir = baseDir ++ "/keypairs/";
let keysetsDir = baseDir ++ "/keysets/";

/**
 * Writes an arbitrary string to cache.
 */
let write = (model, ~filename, contents) => {
  let path =
    switch (model) {
    | Keypair => keypairsDir ++ filename
    | Keyset => keysetsDir ++ filename
    };
  try (Node.Fs.writeFileSync(path, contents, `utf8)) {
  | Js.Exn.Error(e) =>
    switch (Js.Exn.message(e)) {
    | Some(msg) => Js.log({j|Error: $msg|j})
    | None =>
      Js.log(
        {j|An unknown error occured while writing a keypair to $filename|j},
      )
    }
  };
};
