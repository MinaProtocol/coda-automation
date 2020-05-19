type model =
  | Keypair
  | Keyset;

// TODO: Add support for ENV and non Unix environments
let baseDir = "/usr/local/var/coda-network";
let keypairsDir = baseDir ++ "/keypairs/";
let keysetsDir = baseDir ++ "/keysets/";

let modelDir = model =>
  switch (model) {
  | Keypair => keypairsDir
  | Keyset => keysetsDir
  };

[@bs.module "mkdirp"] external mkdirp: string => unit = "sync";

/**
 * Writes an arbitrary string to cache.
 */
let write = (model, ~filename, contents) => {
  let base = modelDir(model);
  mkdirp(base);

  let path = base ++ filename;
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

/**
 * Lists all the entries for given model.
 */
let list = model => modelDir(model)->Node.Fs.readdirSync;
