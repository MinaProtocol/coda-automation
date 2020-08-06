provider helm {
  kubernetes {
    host                   = "https://${data.google_container_cluster.cluster.endpoint}"
    client_certificate     = base64decode(data.google_container_cluster.cluster.master_auth[0].client_certificate)
    client_key             = base64decode(data.google_container_cluster.cluster.master_auth[0].client_key)
    cluster_ca_certificate = base64decode(data.google_container_cluster.cluster.master_auth[0].cluster_ca_certificate)
    token                  = data.google_client_config.current.access_token
    load_config_file       = false
  }
}

# data "helm_repository" "coda_helm_repo" {
#   name = "coda-helm-repo"
#   url  = var.coda_helm_repo
# }


locals {
  seed_peers = [
    "/dns4/seed-node.${var.testnet_name}/tcp/10001/ipfs/${split(",", var.seed_discovery_keypairs[0])[2]}"
    # "/ip4/${module.seed_one.instance_external_ip}/tcp/10001/ipfs/${split(",", module.seed_one.discovery_keypair)[2]}",
    # "/ip4/${module.seed_two.instance_external_ip}/tcp/10001/ipfs/${split(",", module.seed_two.discovery_keypair)[2]}"
  ]

  coda_values = {
      genesis = {
        active = true
        genesis_state_timestamp = var.genesis_timestamp
        ledger = jsonencode(jsondecode(file(var.ledger_config_location)))
      }
      image = var.coda_image
      seedPeers = concat(var.additional_seed_peers, local.seed_peers)
      logLevel             = var.log_level
      logReceivedBlocks    = var.log_received_blocks
    }

  seed_values = {
    testnetName = var.testnet_name
    coda = local.coda_values
    seed = {
      active = true
      discovery_keypair = var.seed_discovery_keypairs[0]
    }
  }

  whale_producer_vars = {
    testnetName = var.testnet_name
    coda = local.coda_values
    
    blockProducer = {
      numProducers            = var.num_whale_block_producers
      labelOffset = var.fish_block_producer_label_offset
      codaPrivkeyPass         = var.block_producer_key_pass
      startingPorts           = var.block_producer_starting_host_port + var.num_whale_block_producers
      keySecretTemplatePrefix = "online-whale-account"
      class      = "whale"
    }
  }

  fish_producer_vars = {
    testnetName = var.testnet_name
    coda = local.coda_values
    blockProducer = {
      numProducers            = var.num_fish_block_producers
      labelOffset = var.fish_block_producer_label_offset
      codaPrivkeyPass         = var.block_producer_key_pass
      startingPorts           = var.block_producer_starting_host_port + var.num_whale_block_producers
      keySecretTemplatePrefix = "online-fish-account"
      class      = "fish"
    }
    agent = {
      active             = var.coda_agent_active
      image              = var.coda_agent_image
      maxTx              = var.agent_max_tx
      minTx              = var.agent_min_tx
      maxFee             = var.agent_max_fee
      minFee             = var.agent_min_fee
    }
  }
  
  snark_worker_vars = {
    testnetName = var.testnet_name
    coda = local.coda_values
    worker = {
      active = true
      numReplicas = var.snark_worker_replicas
    }
    coordinator = {
      active = true
      deployService = true
      publicKey   = var.snark_worker_public_key
      snarkFee    = var.snark_worker_fee
      hostPort    = var.snark_worker_host_port
    }
  }

  archive_node_vars = {
    testnetName = var.testnet_name
    seedPeers  = concat(var.additional_seed_peers, local.seed_peers)
    codaImage  = var.coda_image
    archiveImage = replace(var.coda_image, "codaprotocol/coda-daemon",
                                           "codaprotocol/coda-archive")
  }   

  faucet_vars = {
    testnetName = var.testnet_name
    coda = local.coda_values
    faucet = {
      active = true 
      hostPort = 11000
      image = var.coda_faucet_image
      codaPrivkeyPass         = var.block_producer_key_pass
      amount              = var.coda_faucet_amount
      fee                 = var.coda_faucet_fee
    }
    
  }
}

# Cluster-Local Seed Node
resource "helm_release" "seed" {
  name      = "${var.testnet_name}-seed"
  chart     = "../../../helm/seed-node"
  namespace = kubernetes_namespace.testnet_namespace.metadata[0].name
  values = [
    yamlencode(local.seed_values)
  ]
  wait       = true
}


# Block Producers

resource "helm_release" "whale_producers" {
  name      = "${var.testnet_name}-whale-producers"
  chart     = "../../../helm/block-producer"
  namespace = kubernetes_namespace.testnet_namespace.metadata[0].name
  values = [
    yamlencode(local.whale_producer_vars)
  ]
  wait       = false
  depends_on = [helm_release.seed]
}

resource "helm_release" "fish_producers" {
  name      = "${var.testnet_name}-fish-producers"
  chart     = "../../../helm/block-producer"
  namespace = kubernetes_namespace.testnet_namespace.metadata[0].name
  values = [
    yamlencode(local.fish_producer_vars)
  ]
  wait       = false
  depends_on = [helm_release.seed]
}

# Snark Workers 

resource "helm_release" "snark_workers" {
  name      = "${var.testnet_name}-snark-worker"
  chart     = "../../../helm/snark-worker"
  namespace = kubernetes_namespace.testnet_namespace.metadata[0].name
  values = [
    yamlencode(local.snark_worker_vars)
  ]
  wait       = false
  depends_on = [helm_release.seed]
}

# Archive Node 
# resource "helm_release" "archive_node" {
#   name      = "${var.testnet_name}-archive-node"
#   chart     = "../../../helm/archive-node"
#   namespace = kubernetes_namespace.testnet_namespace.metadata[0].name
#   values = [
#     yamlencode(local.archive_node_vars)
#   ]
#   wait       = false
#   depends_on = [helm_release.seed]
# }

# Discord Faucet 
resource "helm_release" "discord_faucet" {
  name      = "${var.testnet_name}-faucet"
  chart     = "../../../helm/discord-faucet"
  namespace = kubernetes_namespace.testnet_namespace.metadata[0].name
  values = [
    yamlencode(local.faucet_vars)
  ]
  wait       = false
  depends_on = [helm_release.seed]
}