module CodaSDK = O1labsClientSdk.CodaSDK;

[@bs.deriving abstract]
type keypair = {
  publicKey: string,
  privateKey: string,
  nickname: option(string),
};

external toJson: keypair => Js.Json.t = "%identity";

/**
 * Generates a new keypair with an optional nickname
 */
let create = (~nickname: option(string)) => {
  let rawKeys = CodaSDK.genKeys();
  keypair(
    ~publicKey=rawKeys.publicKey,
    ~privateKey=rawKeys.privateKey,
    ~nickname,
  );
};

/**
 * Writes the serialized keypair to disk.
 */
let write = keypair => {
  let filename =
    Config.keypairsDir
    ++ Belt.Option.getWithDefault(keypair->nicknameGet, keypair->publicKeyGet);
  Node.Fs.writeFileSync(
    filename,
    Js.Json.stringify(keypair |> toJson),
    `utf8,
  );
};
