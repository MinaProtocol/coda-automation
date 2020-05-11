resource "kubernetes_namespace" "cluster_namespace" {
  metadata {
    name = var.cluster_namespace
  }
}

data "google_container_cluster" "cluster" {
  name     = var.gke_cluster_name
  location = var.gke_cluster_region
}

provider "kubernetes" {
  host                   = "https://${data.google_container_cluster.cluster.endpoint}"
  client_certificate     = base64decode(data.google_container_cluster.cluster.master_auth[0].client_certificate)
  client_key             = base64decode(data.google_container_cluster.cluster.master_auth[0].client_key)
  cluster_ca_certificate = base64decode(data.google_container_cluster.cluster.master_auth[0].cluster_ca_certificate)
  token                  = data.google_client_config.current.access_token
  load_config_file       = false
}

resource "kubernetes_secret" "google_application_credentials" {
  metadata {
    name = "google-application-credentials"
    namespace = kubernetes_namespace.cluster_namespace.metadata[0].name
    annotations = {
      "kubernetes.io/service-account.name" = "google-application-credentials"
    }
  }
  data = {
    "credentials_json" = base64decode(google_service_account_key.buildkite_svc_key.private_key)
  }
}

resource "kubernetes_secret" "buildkite_agent_token" {
  metadata {
    name = "buildkite-agent-token"
    namespace = kubernetes_namespace.cluster_namespace.metadata[0].name
  }
  data = {
    "agent_token" = base64decode(var.agent_token)
  }
}
