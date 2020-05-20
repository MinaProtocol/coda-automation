// Each entry consists of a publicKey and an optional nickname
type entry = {
  publicKey: string,
  nickname: option(string),
};

type t = {
  name: string,
  entries: array(entry),
};

external toJson: t => Js.Json.t = "%identity";
external fromJson: Js.Json.t => t = "%identity";

type actions =
  | Create
  | Add
  | Remove
  | List
  | Upload;

/**
 * Returns a new empty keyset.
 */
let create = name => {name, entries: [||]};

let stringify = keyset => keyset->toJson->Js.Json.stringify;

/**
 * Writes a keyset to disk.
 */
let write = keyset => {
  let filename = keyset.name;
  Cache.write(Cache.Keyset, ~filename, stringify(keyset));
};

/**
 * Attempts to load a keyset based on the name.
 */
let load = name => {
  open Node.Fs;
  let filename = Cache.keysetsDir ++ name;
  if (existsSync(filename)) {
    let raw = readFileSync(filename, `utf8);
    Some(Js.Json.parseExn(raw)->fromJson);
  } else {
    None;
  };
};

/**
 * Adds a publicKey to a keyset with an optional nickname.
 */
let append = (keyset, ~publicKey, ~nickname) => {
  {
    name: keyset.name,
    entries: Array.append([|{publicKey, nickname}|], keyset.entries),
  };
};

/**
 * Adds a keypair to a keyset based on it's publicKey.
 */
let appendKeypair = (keyset, keypair) =>
  append(
    keyset,
    ~publicKey=keypair.publicKey,
    ~nickname=keypair.nickname,
  );

/**
 * Uploads a serialized keyset to Storage.
 */
let upload = keyset => {
  let filename = Cache.keysetsDir ++ keyset.name;
  let _ = Storage.upload(~bucket=Storage.keysetBucket, ~filename);
  ();
};

type listResponse = {
  remote: array(string),
  local: array(string),
};

/**
 * Returns a Promise that resolves with a list of all keyset names.
 */
let list = () => {
  Storage.list(~bucket=Storage.keysetBucket) |> 
  Js.Promise.then_(remote => {
    let local = Cache.list(Cache.Keyset);
    Js.Promise.resolve({ remote, local })
  });
};
