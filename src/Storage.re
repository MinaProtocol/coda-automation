type t;
type bucket;
type file;

[@bs.module "@google-cloud/storage"] [@bs.new]
external create: unit => t = "Storage";

[@bs.send] external getBucket: (t, string) => bucket = "bucket";

[@bs.send] external getFile: (bucket, string) => file = "file";

type saveOpts = {resumable: bool};

[@bs.send] external save: (file, string, saveOpts) => unit = "save";

let client = create();

let upload = (~bucket: string, ~filename, contents) => {
  client
  ->getBucket(bucket)
  ->getFile(filename)
  ->save(contents, {resumable: false});
};
