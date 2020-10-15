terraform {
  required_version = "~> 0.13.3"
  backend "s3" {
    key     = "terraform-pears.tfstate"
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

locals {
  testnet_name = "pears"
  coda_image = "codaprotocol/coda-daemon:0.0.16-beta7-fix-libp2p-isolation-f070bd7"
  coda_archive_image = "codaprotocol/coda-archive:0.0.16-beta7-feature-mainnet-parameter-test"
  seed_region = "us-east1"
  seed_zone = "us-east1-b"

  seed_discovery_keypairs = [
    "CAESQBEHe2zCcQDHcSaeIydGggamzmTapdCS8SP0hb5FWvYhe9XEygmlUGV4zNu2P8zAIba4X84Gm4usQFLamjRywA8=,CAESIHvVxMoJpVBleMzbtj/MwCG2uF/OBpuLrEBS2po0csAP,12D3KooWJ9mNdbUXUpUNeMnejRumKzmQF15YeWwAPAhTAWB6dhiv",
    "CAESQO+8qvMqTaQEX9uh4NnNoyOy4Xwv3U80jAsWweQ1J37AVgx7kgs4pPVSBzlP7NDANP1qvSvEPOTh2atbMMUO8EQ=,CAESIFYMe5ILOKT1Ugc5T+zQwDT9ar0rxDzk4dmrWzDFDvBE,12D3KooWFcGGeUmbmCNq51NBdGvCWjiyefdNZbDXADMK5CDwNRm5"
  ]
  seed_peer_ids = [
    for keypair in local.seed_discovery_keypairs: split(",", keypair)[2]
  ]
  
  sentry_discovery_keypair = "CAESQN6p1rac1zJHe8rZQf8ljHM+0T9c0E/Ad+kF9xR27Q7xcqPfcnTwfJhAv5X1e3pEo9jr0GzNZAZXYj9hjaXWxRY=,CAESIHKj33J08HyYQL+V9Xt6RKPY69BszWQGV2I/YY2l1sUW,12D3KooWHXsaP1jCYnwbnnr61f4LpsK2ZfrN4tXGx8iVEYB3XBnm"
  sentry_peer_id = split(",", local.sentry_discovery_keypair)[2]

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
}


module "testnet_east" {
  providers = { google = google.google-us-east1 }
  source    = "../../modules/kubernetes/testnet"

  gcloud_seeds = [ module.seed_one, module.seed_two ]

  cluster_name          = "coda-infra-east"
  cluster_region        = "us-east1"
  testnet_name          = local.testnet_name

  coda_image            = local.coda_image
  coda_archive_image    = local.coda_archive_image
  coda_agent_image      = "codaprotocol/coda-user-agent:0.1.6"
  coda_bots_image       = "codaprotocol/coda-bots:0.0.13-beta-1"
  coda_points_image     = "codaprotocol/coda-points-hack:32b.4"

  coda_faucet_amount    = "10000000000"
  coda_faucet_fee       = "100000000"

  runtime_config = local.runtime_config

  seed_zone               = local.seed_zone
  seed_region             = local.seed_region
  seed_discovery_keypairs = local.seed_discovery_keypairs
  seed_direct_peers           = [
    "/dns4/seed-node.${local.testnet_name}/tcp/10001/p2p/${local.seed_peer_ids[0]}"
  ]

  log_level              = "Trace"
  log_txn_pool_gossip    = true
  log_received_blocks    = true

  block_producer_key_pass = "naughty blue worm"
  block_producer_starting_host_port = 10001

  block_producer_configs = concat(
    [
      # "sentry" block producer
      {
        name                   = "whale-block-producer-1-isolated"
        class                  = "whale"
        id                     = 1
        private_key_secret     = "online-whale-account-1-key"
        run_with_user_agent    = false
        run_with_bots          = false
        enable_peer_exchange   = true
        isolated               = true
        enable_gossip_flooding = true
        discovery_keypair      = local.sentry_discovery_keypair
        whitelist              = local.seed_peer_ids
        direct_peers           = [
          "/dns4/seed-node.${local.testnet_name}/tcp/10001/p2p/${local.seed_peer_ids[0]}"
        ]
      }
    ],
    [
      for i in range(2): {
        name                   = "whale-block-producer-${i + 2}"
        class                  = "whale"
        id                     = i + 2
        private_key_secret     = "online-whale-account-${i + 2}-key"
        enable_gossip_flooding = false
        run_with_user_agent    = false
        run_with_bots          = false
        isolated               = false
        enable_peer_exchange   = true
        discovery_keypair      = null
        whitelist              = []
        direct_peers           = []
      }
    ],
    [
      for i in range(3): {
        name                   = "fish-block-producer-${i + 1}"
        class                  = "fish"
        id                     = i + 1
        private_key_secret     = "online-fish-account-${i + 1}-key"
        enable_gossip_flooding = false
        isolated               = false
        enable_peer_exchange   = false
        run_with_user_agent    = true
        run_with_bots          = false
        discovery_keypair      = null
        whitelist              = []
        direct_peers           = []
      }
    ]
  )

  snark_worker_replicas   = 1
  snark_worker_fee        = "0.025"
  snark_worker_public_key = "B62qk4nuKn2U5kb4dnZiUwXeRNtP1LncekdAKddnd1Ze8cWZnjWpmMU"
  snark_worker_host_port  = 10400

  agent_min_fee = "0.06"
  agent_max_fee = "0.1"
  agent_min_tx = "0.0015"
  agent_max_tx = "0.0015"
  agent_send_every_mins = "3"
  agent_tx_batch_size = "3"
}

