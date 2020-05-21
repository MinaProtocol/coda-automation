output "cluster_svc_name" {
  value = google_service_account.gcp_buildkite_account[0].name
}

output "cluster_svc_email" {
  value = google_service_account.gcp_buildkite_account[0].email
}
