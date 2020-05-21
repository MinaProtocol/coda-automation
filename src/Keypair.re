module CodaSDK = O1labsClientSdk.CodaSDK;

type t = {
  publicKey: string,
  privateKey: string,
  nickname: option(string),
};

external toJson: t => Js.Json.t = "%identity";

// HACK: Workaround to get data out of the client sdk
external parseKeys: CodaSDK.keypair => t = "%identity";

let filename = keypair =>
  Belt.Option.getWithDefault(keypair.nickname, keypair.publicKey);

/**
 * Generates a new keypair with an optional nickname
 */
let create = (~nickname: option(string)) => {
  let keys = CodaSDK.genKeys()->parseKeys;
  {publicKey: keys.publicKey, privateKey: keys.privateKey, nickname};
};

/**
 * Writes the serialized keypair to disk.
 */
let write = keypair => {
  Cache.write(
    Cache.Keypair,
    ~filename=filename(keypair),
    keypair->Js.Json.stringifyAny->Belt.Option.getExn,
  );
};

/**
 * Writes the serialized keypair to disk.
 */
let upload = keypair => {
  Storage.upload(~bucket=Storage.keypairBucket, ~filename=filename(keypair))
  |> ignore;
};
