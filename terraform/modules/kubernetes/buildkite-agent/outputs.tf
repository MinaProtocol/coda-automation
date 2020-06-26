output "cluster_svc_name" {

  value = var.k8s_provider == "gke" ? google_service_account.gcp_buildkite_account[0].name : "custom"
}

output "cluster_svc_email" {

  value = var.k8s_provider == "gke" ? google_service_account.gcp_buildkite_account[0].email : "custom"
}
