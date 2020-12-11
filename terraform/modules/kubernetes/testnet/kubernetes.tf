provider kubernetes {
    config_context  = var.k8s_context
}

resource "kubernetes_namespace" "testnet_namespace" {
  metadata {
    name = var.testnet_name
  }
}