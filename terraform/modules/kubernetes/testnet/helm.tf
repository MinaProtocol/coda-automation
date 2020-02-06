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

data "helm_repository" "coda_helm_repo" {
  name = "coda-helm-repo"
  url  = var.coda_helm_repo
}


locals {
  chart_variables = {
    testnetName = var.testnet_name
    snarkWorker = {
      replicas = var.snark_worker_replicas
      fee = var.snark_worker_fee
      key = var.snark_worker_key
    }
    codaImage = var.coda_image
    seedPeers = [
      "/ip4/${module.seed_one.instance_external_ip}/tcp/10002/ipfs/${split(",", module.seed_one.discovery_keypair)[2]}",
      "/ip4/${module.seed_two.instance_external_ip}/tcp/10002/ipfs/${split(",", module.seed_two.discovery_keypair)[2]}"
    ]
    coda_privkey_pass = var.coda_privkey_pass
    starting_ports = var.starting_host_ports
  }
}

resource "helm_release" "testnet" {
  name       = var.testnet_name
  chart = "coda-helm-repo/coda-testnet"
  repository = data.helm_repository.coda_helm_repo.metadata[0].name
  version = var.testnet_helm_chart_version
  namespace  = kubernetes_namespace.testnet_namespace.metadata[0].name
  values = [
    yamlencode(local.chart_variables)
  ]
  wait = false
  depends_on = [module.seed_one, module.seed_two]
}
