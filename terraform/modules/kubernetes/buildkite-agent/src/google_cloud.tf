data "google_client_config" "current" {}

locals {
  gke_context = "gke"
}

resource "google_service_account" "gcp_buildkite_account" {
  count = var.k8s_provider == local.gke_context ? 1 : 0

  account_id   = "buildkite-${var.cluster_name}"
  display_name = "Buildkite Agent Cluster (${var.cluster_name}) service account"
  description  = "GCS service account for Buildkite cluster ${var.cluster_name}"
  project      = "o1labs-192920"
}

resource "google_service_account_key" "buildkite_svc_key" {
  count = var.k8s_provider == local.gke_context ? 1 : 0

  service_account_id = google_service_account.gcp_buildkite_account[0].name
}

