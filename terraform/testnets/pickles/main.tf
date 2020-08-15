terraform {
  required_version = "~> 0.12.0"
  backend "s3" {
    key     = "terraform-pickles.tfstate"
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

<<<<<<< HEAD
locals {
  testnet_name = "pickles"
  coda_image = "codaprotocol/coda-daemon:0.0.16-beta7-debug-adding-ledger-catchup-logs-049e329"
  seed_region = "us-east1"
  seed_zone = "us-east1-b"
  seed_discovery_keypairs = [
 "CAESQNf7ldToowe604aFXdZ76GqW/XVlDmnXmBT+otorvIekBmBaDWu/6ZwYkZzqfr+3IrEh6FLbHQ3VSmubV9I9Kpc=,CAESIAZgWg1rv+mcGJGc6n6/tyKxIehS2x0N1Uprm1fSPSqX,12D3KooWAFFq2yEQFFzhU5dt64AWqawRuomG9hL8rSmm5vxhAsgr" 
]
}

=======
>>>>>>> pickles
module "testnet_east" {
  providers = { google = google.google-us-east1 }
  source    = "../../modules/kubernetes/testnet"

  cluster_name          = "coda-infra-east"
  cluster_region        = "us-east1"
<<<<<<< HEAD
  testnet_name          = local.testnet_name

  coda_image            = local.coda_image
  coda_bots_image       = "codaprotocol/coda-bots:0.0.13-beta-1"

  coda_faucet_amount    = "100000000000"
  coda_faucet_fee       = "1100000000"

  runtime_config = file("./docker-state/genesis_ledger.json")

  seed_zone = local.seed_zone
  seed_region = local.seed_region

  seed_discovery_keypairs = [
 "CAESQNf7ldToowe604aFXdZ76GqW/XVlDmnXmBT+otorvIekBmBaDWu/6ZwYkZzqfr+3IrEh6FLbHQ3VSmubV9I9Kpc=,CAESIAZgWg1rv+mcGJGc6n6/tyKxIehS2x0N1Uprm1fSPSqX,12D3KooWAFFq2yEQFFzhU5dt64AWqawRuomG9hL8rSmm5vxhAsgr" 
]
=======
  testnet_name          = "pickles"

  coda_image            = "codaprotocol/coda-daemon:0.0.14-rosetta-scaffold-inversion-489d898"
  coda_agent_image      = "codaprotocol/coda-user-agent:0.1.5"
  coda_bots_image       = "codaprotocol/coda-bots:0.0.13-beta-1"
  coda_points_image     = "codaprotocol/coda-points-hack:32b.4"

  coda_faucet_amount    = "10000000000"
  coda_faucet_fee       = "100000000"

  runtime_config = <<EOT
    {
      "daemon": {},
      "genesis": { 
        "genesis_state_timestamp": "${timestamp()}",
        "k": 20, 
        "delta": 3
      },
      "proof": {
        "c": 8
      },
      "ledger": ${file("../../../scripts/genesis_ledger.json")}
    }
  EOT

  seed_zone = "us-east1-b"
  seed_region = "us-east1"
>>>>>>> pickles

  log_level              = "Trace"
  log_txn_pool_gossip    = true
  log_received_blocks    = true

  block_producer_key_pass = "naughty blue worm"
<<<<<<< HEAD
  block_producer_starting_host_port = 10005

  block_producer_configs = concat(
    [
      for i in range(0,1): {
        name                   = "whale-block-producer-${i + 1}"
        class                  = "whale"
        id                     = i + 1
        private_key_secret     = "online-whale-${i + 1}-key"
        enable_gossip_flooding = false
        run_with_user_agent    = false
        run_with_bots          = true
      }
    ],
    [
      for i in range(1,5): {
        name                   = "whale-block-producer-${i + 1}"
        class                  = "whale"
        id                     = i + 1
        private_key_secret     = "online-whale-${i + 1}-key"
=======
  block_producer_starting_host_port = 10001

  block_producer_configs = concat(
    [
      for i in range(5): {
        name                   = "whale-block-producer-${i + 1}"
        class                  = "whale"
        id                     = i + 1
        private_key_secret     = "online-whale-account-${i + 1}-key"
        enable_gossip_flooding = false
        run_with_user_agent    = false
        run_with_bots          = false
      }
    ],
    [
      for i in range(400): {
        name                   = "fish-block-producer-${i + 1}"
        class                  = "fish"
        id                     = i + 1
        private_key_secret     = "online-fish-account-${i + 1}-key"
>>>>>>> pickles
        enable_gossip_flooding = false
        run_with_user_agent    = false
        run_with_bots          = false
      }
    ]
  )

<<<<<<< HEAD
  snark_worker_replicas = 8
  snark_worker_fee      = "10"
  snark_worker_public_key = "B62qotoVypDR2w7yUVSxFmyhbcn2SqdSwoJDPo5YmPyha7MyXPY891G"
  snark_worker_host_port = 10400
}

=======
  snark_worker_replicas = 128
  snark_worker_fee      = "0.025"
  snark_worker_public_key = "B62qk4nuKn2U5kb4dnZiUwXeRNtP1LncekdAKddnd1Ze8cWZnjWpmMU"
  snark_worker_host_port = 10400

  agent_min_fee = "0.06"
  agent_max_fee = "0.1"
  agent_min_tx = "0.0015"
  agent_max_tx = "0.0015"
}
>>>>>>> pickles
