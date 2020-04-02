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
    numProducers            = var.num_whale_block_producers
    testnetName             = var.testnet_name
    codaImage               = var.coda_image
    seedPeers               = concat(var.additional_seed_peers, local.seed_peers)
    codaPrivkeyPass         = var.block_producer_key_pass
    startingPorts           = var.block_producer_starting_host_port
    keySecretTemplatePrefix = "online-whale-account"
    blockProducerClass      = "whale"
  }
  fish_producer_vars = {
    numProducers            = var.num_fish_block_producers
    labelOffset = var.fish_block_producer_label_offset
    testnetName             = var.testnet_name
    codaImage               = var.coda_image
    seedPeers               = concat(var.additional_seed_peers, local.seed_peers)
    codaPrivkeyPass         = var.block_producer_key_pass
    startingPorts           = var.block_producer_starting_host_port + var.num_whale_block_producers
    keySecretTemplatePrefix = "online-fish-account"
    blockProducerClass      = "fish"
    agentImage              = var.coda_agent_image
    botsImage               = var.coda_bots_image
    faucetAmount            = var.coda_faucet_amount
    faucetFee               = var.coda_faucet_fee
  }
  snark_worker_vars = {
    testnetName = var.testnet_name
    numReplicas = var.snark_worker_replicas
    publicKey   = var.snark_worker_public_key
    snarkFee    = var.snark_worker_fee
    codaImage   = var.coda_image
    seedPeers   = concat(var.additional_seed_peers, local.seed_peers)
    hostPort    = var.snark_worker_host_port
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
