data "google_container_cluster" "cluster" {
  count            = "${var.k8s_provider == "gcp" ? 1 : 0}"

  name     = var.k8s_cluster_name
  location = var.k8s_cluster_region
}

provider "kubernetes" {
  config_context         = var.k8s_provider
  config_context_cluster = var.k8s_provider
}

resource "kubernetes_namespace" "cluster_namespace" {
  metadata {
    name = var.cluster_namespace
  }
}
