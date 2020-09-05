# locals {
#   central_prometheus_helm_values = {
#     server = {
#       global = {
#         external_labels = {
#           origin_prometheus = "central-prometheus"
#         }
#       }
#       remoteWrite = [
#         {
#           url = jsondecode(data.aws_secretsmanager_secret_version.current_prometheus_remote_write_config.secret_string)["remote_write_uri"]
#           basic_auth = {
#             username = jsondecode(data.aws_secretsmanager_secret_version.current_prometheus_remote_write_config.secret_string)["remote_write_username"]
#             password = jsondecode(data.aws_secretsmanager_secret_version.current_prometheus_remote_write_config.secret_string)["remote_write_password"]
#           }
#         }
#       ]
#     }
#   }
# }

# provider "google" {
#   alias   = "google_central"
#   project = "o1labs-192920"
#   region  = "us-central1"
#   zone    = "us-central1-b"
# }

# resource "google_container_cluster" "coda_cluster_central" {
#   provider = google.google_central
#   name     = "coda-infra-central"
#   location = "us-central1"
#   min_master_version = "1.15"

#   # We can't create a cluster with no node pool defined, but we want to only use
#   # separately managed node pools. So we create the smallest possible default
#   # node pool and immediately delete it.
#   remove_default_node_pool = true
#   initial_node_count       = 1

#   master_auth {
#     username = ""
#     password = ""

#     client_certificate_config {
#       issue_client_certificate = false
#     }
#   }
# }

# resource "google_container_node_pool" "central_primary_nodes" {
#   provider = google.google_central
#   name       = "coda-infra-central"
#   location   = "us-central1"
#   cluster    = google_container_cluster.coda_cluster_central.name
#   node_count = local.num_nodes_per_zone
#   autoscaling {
#     min_node_count = 0
#     max_node_count = 8
#   }
#   node_config {
#     preemptible  = false
#     machine_type = local.node_type

#     metadata = {
#       disable-legacy-endpoints = "true"
#     }

#     oauth_scopes = [
#       "https://www.googleapis.com/auth/logging.write",
#       "https://www.googleapis.com/auth/monitoring",
#     ]
#   }
# }

# ## Helm 

# provider helm {
#   alias = "helm_central"
#   kubernetes {
#     host                   = "https://${google_container_cluster.coda_cluster_central.endpoint}"
#     client_certificate     = base64decode(google_container_cluster.coda_cluster_central.master_auth[0].client_certificate)
#     client_key             = base64decode(google_container_cluster.coda_cluster_central.master_auth[0].client_key)
#     cluster_ca_certificate = base64decode(google_container_cluster.coda_cluster_central.master_auth[0].cluster_ca_certificate)
#     token                  = data.google_client_config.current.access_token
#     load_config_file       = false
#   }
# }

# resource "helm_release" "central_prometheus" {
#   provider  = helm.helm_central
#   name      = "central-prometheus"
#   chart     = "stable/prometheus"
#   namespace = "default"
#   values = [
#     yamlencode(local.central_prometheus_helm_values)
#   ]
#   wait       = true
#   depends_on = [google_container_cluster.coda_cluster_central]
# }

