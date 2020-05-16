module CodaSDK = O1labsClientSdk.CodaSDK;

[@bs.deriving abstract]
type keypair = {
  publicKey: string,
  privateKey: string,
  nickname: option(string),
};

external toJson: keypair => Js.Json.t = "%identity";

// HACK: Workaround to get data out of the client sdk
external keysToDict: CodaSDK.keypair => Js.Dict.t(string) = "%identity";

/**
 * Generates a new keypair with an optional nickname
 */
let create = (~nickname: option(string)) => {
  let keysRaw = CodaSDK.genKeys();
  let keysDict = keysToDict(keysRaw);
  let getValue = key => Js.Dict.get(keysDict, key) |> Belt.Option.getExn;
  keypair(
    ~publicKey=getValue("publicKey"),
    ~privateKey=getValue("privateKey"),
    ~nickname,
  );
};

/**
 * Writes the serialized keypair to disk.
 */
let write = keypair => {
  let filename =
    Belt.Option.getWithDefault(keypair->nicknameGet, keypair->publicKeyGet);
  Cache.write(Cache.Keypair, ~filename, toJson(keypair)->Js.Json.stringify);
};

/**
 * Writes the serialized keypair to disk.
 */
let uplaod = keypair => {
  let filename =
    Belt.Option.getWithDefault(keypair->nicknameGet, keypair->publicKeyGet);
  Storage.upload(
    ~bucket=Storage.keypairBucket,
    ~filename,
    toJson(keypair)->Js.Json.stringify,
  );
};
