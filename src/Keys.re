module CodaSDK = O1labsClientSdk.CodaSDK;

type keypair = {
  publicKey: string,
  privateKey: string,
  nickname: option(string),
};

let create = (~nickname: option(string)) => {
  let rawKeys = CodaSDK.genKeys();
  {publicKey: rawKeys.publicKey, privateKey: rawKeys.privateKey, nickname};
};
