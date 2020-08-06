locals {
  graphql_proxy_vars = {
    coda = {
      genesis = {
        active = false
      }
      image = var.coda_image
      seedPeers = concat(var.additional_seed_peers, local.seed_peers)
    }
    proxy = {
      image = var.graphql_proxy_image
    }
  }
}

# Graphql Proxy
resource "helm_release" "graphql_proxy" {
  name      = "${var.testnet_name}-graphql-proxy"
  chart     = "../../../helm/graphql-proxy"
  namespace = kubernetes_namespace.testnet_namespace.metadata[0].name
  values = [
    yamlencode(local.graphql_proxy_vars)
  ]
  wait       = false
  depends_on = [module.seed_one, module.seed_two]
}