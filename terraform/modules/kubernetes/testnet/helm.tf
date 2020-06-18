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
  whale_producer_vars = {
    numProducers             = var.num_whale_block_producers
    blockProducersWithBots   = var.whale_block_producers_with_bots
    blockProducersWithPoints = var.whale_block_producers_with_points
    testnetName              = var.testnet_name
    codaImage                = var.coda_image
    botsImage                = var.coda_bots_image
    pointsImage              = var.coda_points_image
    seedPeers                = concat(var.additional_seed_peers, local.seed_peers)
    codaPrivkeyPass          = var.block_producer_key_pass
    codaLogLevel             = var.whale_block_producer_log_level
    logReceivedBlocks        = var.whale_block_producer_log_received_blocks
    logTxnPoolGossip         = var.whale_block_producer_log_txn_pool_gossip
    startingPorts            = var.block_producer_starting_host_port
    keySecretTemplatePrefix  = "online-whale-account"
    blockProducerClass       = "whale"
    enableGossipFlooding     = true
  }
  fish_producer_vars = {
    numProducers                 = var.num_fish_block_producers
    labelOffset                  = var.fish_block_producer_label_offset
    blockProducersWithUserAgents = var.fish_block_producers_with_user_agents
    blockProducersWithBots       = var.fish_block_producers_with_bots
    blockProducersWithPoints     = var.fish_block_producers_with_points
    testnetName                  = var.testnet_name
    codaImage                    = var.coda_image
    agentImage                   = var.coda_agent_image
    botsImage                    = var.coda_bots_image
    pointsImage                  = var.coda_points_image
    seedPeers                    = concat(var.additional_seed_peers, local.seed_peers)
    codaPrivkeyPass              = var.block_producer_key_pass
    codaLogLevel                 = var.fish_block_producer_log_level
    logReceivedBlocks            = var.fish_block_producer_log_received_blocks
    logTxnPoolGossip             = var.fish_block_producer_log_txn_pool_gossip
    startingPorts                = var.block_producer_starting_host_port + var.num_whale_block_producers
    keySecretTemplatePrefix      = "online-fish-account"
    blockProducerClass           = "fish"
    agentMinFee                  = var.agent_min_fee
    agentMaxFee                  = var.agent_max_fee
    agentMinTx                   = var.agent_min_tx
    agentMaxTx                   = var.agent_max_tx
    faucetAmount                 = var.coda_faucet_amount
    faucetFee                    = var.coda_faucet_fee
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

resource "helm_release" "whale_producers" {
  name      = "${var.testnet_name}-whale-producers"
  chart     = "../../../helm/block-producer"
  namespace = kubernetes_namespace.testnet_namespace.metadata[0].name
  values = [
    yamlencode(local.whale_producer_vars)
  ]
  wait       = false
  depends_on = [module.seed_one, module.seed_two]
}

resource "helm_release" "fish_producers" {
  name      = "${var.testnet_name}-fish-producers"
  chart     = "../../../helm/block-producer"
  namespace = kubernetes_namespace.testnet_namespace.metadata[0].name
  values = [
    yamlencode(local.fish_producer_vars)
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