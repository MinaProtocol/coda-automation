provider helm {
  kubernetes {
    host     = "https://${data.google_container_cluster.cluster.endpoint}"
    client_certificate     = base64decode(data.google_container_cluster.cluster.master_auth[0].client_certificate)
    client_key             = base64decode(data.google_container_cluster.cluster.master_auth[0].client_key)
    cluster_ca_certificate = base64decode(data.google_container_cluster.cluster.master_auth[0].cluster_ca_certificate)
    token = data.google_client_config.current.access_token
    load_config_file = false 
  }
}

# data "helm_repository" "coda_helm_repo" {
#   name = "coda-helm-repo"
#   url  = var.coda_helm_repo
# }


locals {
  seed_peers = [
    "/ip4/${module.seed_one.instance_external_ip}/tcp/10002/ipfs/${split(",", module.seed_one.discovery_keypair)[2]}",
    "/ip4/${module.seed_two.instance_external_ip}/tcp/10002/ipfs/${split(",", module.seed_two.discovery_keypair)[2]}"
  ]
  whale_producer_vars = {
    numProducers = var.num_whale_block_producers
    testnetName = var.testnet_name
    codaImage = var.coda_image
    seedPeers = local.seed_peers
    codaPrivkeyPass = var.coda_privkey_pass
    startingPorts = var.starting_host_ports
    keySecretTemplatePrefix = "block-producer"
    blockProducerClass = "whale"
  }
  fish_producer_vars = {
    numProducers = var.num_fish_block_producers
    testnetName = var.testnet_name
    codaImage = var.coda_image
    seedPeers = local.seed_peers
    codaPrivkeyPass = var.coda_privkey_pass
    startingPorts = var.starting_host_ports
    keySecretTemplatePrefix = "fish-account"
    blockProducerClass = "fish"
  }
}

resource "helm_release" "whale_producers" {
  name       = "${var.testnet_name}-whale-producers"
  chart = "../../../helm/block-producer"
  namespace  = kubernetes_namespace.testnet_namespace.metadata[0].name
  values = [
    yamlencode(local.whale_producer_vars)
  ]
  wait = false
  depends_on = [module.seed_one, module.seed_two]
}

resource "helm_release" "fish_producers" {
  name       = "${var.testnet_name}-fish-producers"
  chart = "../../../helm/block-producer"
  namespace  = kubernetes_namespace.testnet_namespace.metadata[0].name
  values = [
    yamlencode(local.fish_producer_vars)
  ]
  wait = false
  depends_on = [module.seed_one, module.seed_two]
}