/**
 * Bindings to @google-cloud/storage
 */

type t;
type bucket;
type file;

[@bs.module "@google-cloud/storage"] [@bs.new]
external create: unit => t = "Storage";

[@bs.send] external getBucket: (t, string) => bucket = "bucket";

[@bs.send] external getFile: (bucket, string) => file = "file";

[@bs.send]
external getFiles:
  (bucket, (option(Js.Exn.t), option(file) => unit)) => file =
  "getFiles";

type saveOpts = {resumable: bool};
[@bs.send]
external save: (file, string, saveOpts, Js.Exn.t => unit) => unit = "save";

// Initialize our Storage client
let client = create();

// TODO: Load these from environment variables
let keypairBucket = "network-keypairs";
let keysetBucket = "network-keysets";

let upload = (~bucket, ~filename, contents, onError) => {
  Js.log({j|Uploading $filename|j});
  try (
    client
    ->getBucket(bucket)
    ->getFile(filename)
    ->save(contents, {resumable: false}, onError)
  ) {
  | Js.Exn.Error(e) =>
    switch (Js.Exn.message(e)) {
    | Some(msg) => Js.log({j|Error: $msg|j})
    | None =>
      Js.log(
        {j|An unknown error occured while uploading file $filename to $bucket.|j},
      )
    }
  };
};

let list = (~bucket, cb) => {
  client->getBucket(bucket)->getFiles(cb);
};
