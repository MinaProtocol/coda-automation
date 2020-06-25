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
    "/ip4/${module.seed_one.instance_external_ip}/tcp/10001/ipfs/${split(",", module.seed_one.discovery_keypair)[2]}",
    "/ip4/${module.seed_two.instance_external_ip}/tcp/10001/ipfs/${split(",", module.seed_two.discovery_keypair)[2]}"
  ]
  block_producer_vars = {
    testnetName = var.testnet_name

    coda = {
      image       = var.coda_image
      privkeyPass = var.block_producer_key_pass
      seedPeers   = concat(var.additional_seed_peers, local.seed_peers)
    }

    userAgent = {
      image  = var.coda_agent_image
      minFee = var.agent_min_fee
      maxFee = var.agent_max_fee
      minTx  = var.agent_min_tx
      maxTx  = var.agent_max_tx
    }

    bots = {
      image  = var.coda_bots_image
      faucet = {
        amount = var.coda_faucet_amount
        fee    = var.coda_faucet_fee
      }
    }

    points = {
      image = var.coda_points_image
    }

    blockProducerConfigs = [
      for index, config in var.block_producer_configs: {
        name                 = config.name
        class                = config.class
        externalPort         = var.block_producer_starting_host_port + index
        runWithUserAgent     = config.run_with_user_agent
        runWithBots          = config.run_with_bots
        runWithPoints        = config.run_with_points
        logLevel             = config.log_level
        logReceivedBlocks    = config.log_received_blocks
        logTxnPoolGossip     = config.log_txn_pool_gossip
        enableGossipFlooding = config.enable_gossip_flooding
        privateKeySecret     = "online-${config.class}-account-${index}-key"
      }
    ]
  }
  snark_worker_vars = {
    testnetName = var.testnet_name
    coda = {
      genesis = {
        active = false
      }
      image = var.coda_image
      seedPeers = concat(var.additional_seed_peers, local.seed_peers)
    }
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
}

# Block Producers

resource "helm_release" "block_producers" {
  name      = "${var.testnet_name}-block-producers"
  chart     = "../../../helm/block-producer"
  namespace = kubernetes_namespace.testnet_namespace.metadata[0].name
  values = [
    yamlencode(local.block_producer_vars)
  ]
  wait       = false
  depends_on = [module.seed_one, module.seed_two]
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
  depends_on = [module.seed_one, module.seed_two]
}

resource "helm_release" "archive_node" {
  name      = "${var.testnet_name}-archive-node"
  chart     = "../../../helm/archive-node"
  namespace = kubernetes_namespace.testnet_namespace.metadata[0].name
  values = [
    yamlencode(local.archive_node_vars)
  ]
  wait       = false
  depends_on = [module.seed_one, module.seed_two]
}
