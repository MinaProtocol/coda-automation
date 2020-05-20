module CodaSDK = O1labsClientSdk.CodaSDK;

type t = {
  publicKey: string,
  privateKey: string,
  nickname: option(string),
};

external toJson: t => Js.Json.t = "%identity";

// HACK: Workaround to get data out of the client sdk
external keysToDict: CodaSDK.keypair => Js.Dict.t(string) = "%identity";

let filename = keypair =>
  Belt.Option.getWithDefault(keypair.nickname, keypair.publicKey);

/**
 * Generates a new keypair with an optional nickname
 */
let create = (~nickname: option(string)) => {
  let keysRaw = CodaSDK.genKeys();
  let keysDict = keysToDict(keysRaw);
  let getValue = key => Js.Dict.get(keysDict, key) |> Belt.Option.getExn;
  {
    publicKey: getValue("publicKey"),
    privateKey: getValue("privateKey"),
    nickname,
  };
};

/**
 * Writes the serialized keypair to disk.
 */
let write = keypair => {
  Cache.write(
    Cache.Keypair,
    ~filename=filename(keypair),
    toJson(keypair)->Js.Json.stringify,
  );
};

/**
 * Writes the serialized keypair to disk.
 */
let uplaod = keypair => {
  let _ =
    Storage.upload(
      ~bucket=Storage.keypairBucket,
      ~filename=filename(keypair),
    );
  ();
};
