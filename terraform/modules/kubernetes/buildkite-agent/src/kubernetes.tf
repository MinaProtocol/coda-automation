provider kubernetes {
  config_context         = var.k8s_provider
}

data "google_container_cluster" "cluster" {
  count = "${var.k8s_provider == local.gke_context ? 1 : 0}"

  name     = var.k8s_cluster_name
  location = var.k8s_cluster_region
  project  = local.gke_project
}

resource "kubernetes_namespace" "cluster_namespace" {
  metadata {
    name = var.cluster_name
  }
}
