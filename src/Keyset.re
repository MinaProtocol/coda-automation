// Each entry consists of a publicKey and an optional nickname
[@bs.deriving abstract]
type entry = {
  publicKey: string,
  nickname: option(string),
};

[@bs.deriving abstract]
type t = {
  name: string,
  entries: list(entry),
};

external toJson: t => Js.Json.t = "%identity";

/**
 * Returns a new empty keyset.
 */
let create = name => t(~name, ~entries=[]);

/**
 * Writes a keyset to disk.
 */
let write = keyset => {
  let filename = keyset->nameGet;
  Cache.write(Cache.Keyset, ~filename, Js.Json.stringify(keyset |> toJson));
};

/**
 * Attempts to load a keyset based on the name.
 */
let load = name => {
  open Node.Fs;
  let filename = Config.keysetsDir ++ name;
  if (existsSync(filename)) {
    Some(readFileSync(filename, `utf8));
  } else {
    None;
  };
};

/**
 * Adds a publicKey to a keyset with an optional nickname.
 */
let append = (keyset, ~publicKey, ~nickname) => {
  t(
    ~name=keyset->nameGet,
    ~entries=[entry(~publicKey, ~nickname), ...keyset->entriesGet],
  );
};

/**
 * Adds a keypair to a keyset based on it's publicKey.
 */
let appendKeypair = (keyset, keypair) =>
  append(
    keyset,
    ~publicKey=keypair->publicKeyGet,
    ~nickname=keypair->nicknameGet,
  );

/**
 * Uploads a serialized keyset to Storage.
 */
let upload: t => unit =
  keyset => {
    Storage.upload(
      ~bucket=Storage.keysetBucket,
      ~filename=keyset->nameGet,
      Js.Json.stringify(keyset |> toJson),
    );
  };
