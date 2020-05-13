data "google_client_config" "current" {}

resource "google_service_account" "gcp_buildkite_account" {
  account_id   = "buildkite-${var.cluster_name}"
  display_name = "Buildkite Agent Cluster (${var.cluster_name}) service account"
  description  = "GCS service account for Buildkite cluster ${var.cluster_name}"
  project      = "o1labs-192920"
}

resource "google_service_account_key" "buildkite_svc_key" {
  service_account_id = google_service_account.gcp_buildkite_account.name
}

