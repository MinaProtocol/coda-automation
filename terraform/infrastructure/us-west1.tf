# Testnets

locals {
  region = "us-west1"

  west1_prometheus_helm_values = {
    server = {
      global = {
        external_labels = {
          origin_prometheus = "west1-prometheus"
        }
      }
      persistentVolume = {
        size = "50Gi"
      }
      remoteWrite = [
        {
          url = jsondecode(data.aws_secretsmanager_secret_version.current_prometheus_remote_write_config.secret_string)["remote_write_uri"]
          basic_auth = {
            username = jsondecode(data.aws_secretsmanager_secret_version.current_prometheus_remote_write_config.secret_string)["remote_write_username"]
            password = jsondecode(data.aws_secretsmanager_secret_version.current_prometheus_remote_write_config.secret_string)["remote_write_password"]
          }
          write_relabel_configs = [
            {
              source_labels: ["__name__"]
              regex: "(container.*|Coda.*)"
              action: "keep"
            }
          ]
        }
      ]
    }
  }
}

provider "google" {
  alias   = "google_west1"
  project = "o1labs-192920"
  region  = local.region
}

data "google_compute_zones" "west1_available" {
  project = "o1labs-192920"
  region = local.region
  status = "UP"
}

resource "google_container_cluster" "mina_integration_west1" {
  provider = google.google_west1
  name     = "mina-integration-west1"
  location = local.region
  min_master_version = "1.16"

  node_locations = data.google_compute_zones.west1_available.names

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  master_auth {
    username = ""
    password = ""

    client_certificate_config {
      issue_client_certificate = false
    }
  }
}

resource "google_container_node_pool" "west1_integration_primary" {
  provider = google.google_west1
  name       = "mina-integration-primary"
  location   = local.region
  cluster    = google_container_cluster.mina_integration_west1.name
  node_count = 2
  autoscaling {
    min_node_count = 0
    max_node_count = 5
  }
  node_config {
    preemptible  = true
    machine_type = "n1-standard-16"
    disk_size_gb = 100

    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}

provider helm {
  alias = "helm_west1"
  kubernetes {
    host                   = "https://${google_container_cluster.mina_integration_west1.endpoint}"
    client_certificate     = base64decode(google_container_cluster.mina_integration_west1.master_auth[0].client_certificate)
    client_key             = base64decode(google_container_cluster.mina_integration_west1.master_auth[0].client_key)
    cluster_ca_certificate = base64decode(google_container_cluster.mina_integration_west1.master_auth[0].cluster_ca_certificate)
    token                  = data.google_client_config.current.access_token
    load_config_file       = false
  }
}

resource "helm_release" "west1_prometheus" {
  provider  = helm.helm_west1
  name      = "west1-prometheus"
  chart     = "stable/prometheus"
  namespace = "default"
  values = [
    yamlencode(local.west1_prometheus_helm_values)
  ]
  wait       = true
  depends_on = [google_container_cluster.mina_integration_west1]
  force_update  = true
}
