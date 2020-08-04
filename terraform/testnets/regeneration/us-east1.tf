provider "google" {
  alias   = "google-us-east1"
  project = "o1labs-192920"
  region  = "us-east1"
  zone    = "us-east1-b"
}


module "testnet_east" {
  providers = {
    google = google.google-us-east1
  }
  source                = "../../modules/kubernetes/testnet"
  cluster_name          = "coda-infra-east"
  cluster_region        = "us-east1"
  testnet_name          = local.testnet_name
  coda_image            = local.coda_image
  coda_faucet_image     = "codaprotocol/coda-bots:0.0.13-beta-1"
  genesis_timestamp     = timestamp()
  ledger_config_location = local.ledger_config_location

  seed_zone = "us-east1-b"
  seed_region = "us-east1"

  num_whale_block_producers = 5
  num_fish_block_producers = 10
  block_producer_key_pass = "naughty blue worm"
  block_producer_starting_host_port = 10001

  snark_worker_replicas = 1
  snark_worker_fee      = 0.00000006         
  snark_worker_public_key = "4vsRCVQZ41uqXfVVfkBNUuNNS7PgSJGdMDNAyKGDdU1WkdxxyxQ7oMdFcjDRf45fiGKkdYKkLPBrE1KnxmyBuvaTW97A5C8XjNSiJmvo9oHa4AwyVsZ3ACaspgQ3EyxQXk6uujaxzvQhbLDx"
  snark_worker_host_port = 10400
}

