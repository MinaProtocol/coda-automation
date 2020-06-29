locals {
  east_prometheus_helm_values = {
    server = {
      global = {
        external_labels = {
          origin_prometheus = "east-prometheus"
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
  alias   = "google_east"
  project = "o1labs-192920"
  region  = "us-east1"
  zone    = "us-east1-a"
}

resource "google_container_cluster" "coda_cluster_east" {
  provider = google.google_east
  name     = "coda-infra-east"
  location = "us-east1"
  min_master_version = "1.15"

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

resource "google_container_node_pool" "east_primary_nodes" {
  provider = google.google_east
  name       = "coda-infra-east"
  location   = "us-east1"
  cluster    = google_container_cluster.coda_cluster_east.name
  node_count = local.num_nodes_per_zone
  autoscaling {
    min_node_count = 0
    max_node_count = 15
  }
  node_config {
    preemptible  = false
    machine_type = local.node_type
    disk_size_gb = 500

    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}

resource "google_container_node_pool" "east_experimental_nodes" {
  provider = google.google_east
  name       = "coda-infra-compute"
  location   = "us-east1"
  cluster    = google_container_cluster.coda_cluster_east.name
  node_count = local.num_nodes_per_zone
  autoscaling {
    min_node_count = 0
    max_node_count = 3
  }
  node_config {
    preemptible  = true
    machine_type = "c2-standard-30"
    disk_size_gb = 500

    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}

## Helm 

provider helm {
  alias = "helm_east"
  kubernetes {
    host                   = "https://${google_container_cluster.coda_cluster_east.endpoint}"
    client_certificate     = base64decode(google_container_cluster.coda_cluster_east.master_auth[0].client_certificate)
    client_key             = base64decode(google_container_cluster.coda_cluster_east.master_auth[0].client_key)
    cluster_ca_certificate = base64decode(google_container_cluster.coda_cluster_east.master_auth[0].cluster_ca_certificate)
    token                  = data.google_client_config.current.access_token
    load_config_file       = false
  }
}

resource "helm_release" "east_prometheus" {
  provider  = helm.helm_east
  name      = "east-prometheus"
  chart     = "stable/prometheus"
  namespace = "default"
  values = [
    yamlencode(local.east_prometheus_helm_values)
  ]
  wait       = true
  depends_on = [google_container_cluster.coda_cluster_east]
}
