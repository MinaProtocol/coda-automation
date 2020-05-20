let Volume = ../Lib/Volume.dhall
in {
  images: {
    coda: Text
  },
  volumes: {
    codaConfig: Volume.Type
  }
}
