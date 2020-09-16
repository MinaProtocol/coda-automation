terraform {
  required_version = "~> 0.12.0"
  backend "s3" {
    key     = "terraform-test-public-deploy.tfstate"
    encrypt = true
    region  = "us-west-2"
    bucket  = "o1labs-terraform-state"
    acl     = "bucket-owner-full-control"
  }
}

provider "aws" {
  region = "us-west-2"
}

provider "google" {
  alias   = "google-us-east1"
  project = "o1labs-192920"
  region  = "us-east1"
  zone    = "us-east1-b"
}

module "testnet_east" {
  providers = { google = google.google-us-east1 }
  source    = "../../modules/kubernetes/testnet"

  cluster_name          = "coda-infra-east"
  cluster_region        = "us-east1"
  testnet_name          = "test-public-deploy"

  coda_image            = "codaprotocol/coda-daemon:0.0.16-beta-hotfix-master-fix-genesis-timestamp-ca93dd9"
  coda_bots_image       = "codaprotocol/coda-bots:0.0.13-beta-1"

  coda_faucet_amount    = "10000000000"
  coda_faucet_fee       = "100000000"

  seed_zone = "us-east1-b"
  seed_region = "us-east1"

  log_level              = "Trace"
  log_txn_pool_gossip    = true
  log_received_blocks    = true

  block_producer_key_pass = "naughty blue worm"
  block_producer_starting_host_port = 10001

  block_producer_configs = concat(
    [
      for i in range(5): {
        name                   = "whale-block-producer-${i + 1}"
        class                  = "whale"
        id                     = i + 1
        private_key_secret     = "online-whale-${i + 1}-key"
        enable_gossip_flooding = false
        run_with_user_agent    = false
        run_with_bots          = true
      }
    ]
  )

  snark_worker_replicas = 8
  snark_worker_fee      = "10"
  snark_worker_public_key = "B62qotoVypDR2w7yUVSxFmyhbcn2SqdSwoJDPo5YmPyha7MyXPY891G"
  snark_worker_host_port = 10400
}

locals {
  testnet_name = "test-public-deploy"
  coda_image = "codaprotocol/coda-daemon:0.0.16-beta-hotfix-master-fix-genesis-timestamp-ca93dd9"
  seed_region = "us-east1"
  seed_zone = "us-east1-b"
  seed_discovery_keypairs = [
  "CAESQBEHe2zCcQDHcSaeIydGggamzmTapdCS8SP0hb5FWvYhe9XEygmlUGV4zNu2P8zAIba4X84Gm4usQFLamjRywA8=,CAESIHvVxMoJpVBleMzbtj/MwCG2uF/OBpuLrEBS2po0csAP,12D3KooWJ9mNdbUXUpUNeMnejRumKzmQF15YeWwAPAhTAWB6dhiv",
  "CAESQO+8qvMqTaQEX9uh4NnNoyOy4Xwv3U80jAsWweQ1J37AVgx7kgs4pPVSBzlP7NDANP1qvSvEPOTh2atbMMUO8EQ=,CAESIFYMe5ILOKT1Ugc5T+zQwDT9ar0rxDzk4dmrWzDFDvBE,12D3KooWFcGGeUmbmCNq51NBdGvCWjiyefdNZbDXADMK5CDwNRm5" ]
}
