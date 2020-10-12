provider "google" {
  alias   = "google_central1"
  project = "o1labs-192920"
  region  = "us-central1"
}

# Testnets

locals {
  central1_prometheus_helm_values = {
    server = {
      global = {
        external_labels = {
          origin_prometheus = "central1-prometheus"
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

resource "google_container_cluster" "coda_cluster_central1" {
  provider = google.google_central1
  name     = "coda-infra-central1"
  location = "us-central1"
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

resource "google_container_node_pool" "central1_primary_nodes" {
  provider = google.google_central1
  name       = "coda-infra-central1"
  location   = "us-central1"
  cluster    = google_container_cluster.coda_cluster_central1.name
  node_count = 4
  autoscaling {
    min_node_count = 0
    max_node_count = 10
  }
  node_config {
    preemptible  = false
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

resource "google_container_node_pool" "central1_experimental_nodes" {
  provider = google.google_central1
  name       = "coda-infra-central1"
  location   = "us-central1"
  cluster    = google_container_cluster.coda_cluster_central1.name
  node_count = 1
  autoscaling {
    min_node_count = 0
    max_node_count = 5
  }
  node_config {
    preemptible  = false
    machine_type = "n2d-standard-16"
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
  alias = "helm_central1"
  kubernetes {
    host                   = "https://${google_container_cluster.coda_cluster_central1.endpoint}"
    client_certificate     = base64decode(google_container_cluster.coda_cluster_central1.master_auth[0].client_certificate)
    client_key             = base64decode(google_container_cluster.coda_cluster_central1.master_auth[0].client_key)
    cluster_ca_certificate = base64decode(google_container_cluster.coda_cluster_central1.master_auth[0].cluster_ca_certificate)
    token                  = data.google_client_config.current.access_token
    load_config_file       = false
  }
}

resource "helm_release" "central1_prometheus" {
  provider  = helm.helm_central1
  name      = "central1-prometheus"
  chart     = "stable/prometheus"
  namespace = "default"
  values = [
    yamlencode(local.central1_prometheus_helm_values)
  ]
  wait       = true
  depends_on = [google_container_cluster.coda_cluster_central1]
  force_update  = true
}

# Buildkite

resource "google_container_cluster" "buildkite_infra_central1" {
  provider = google.google_central1
  name     = "buildkite-infra-central1"
  location = "us-central1"
  min_master_version = "1.15"

  node_locations = [
    "us-central1-a",
    "us-central1-b",
    "us-central1-c",
    "us-central1-f"
  ]

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

resource "google_container_node_pool" "central1_compute_nodes" {
  provider = google.google_central1
  name     = "buildkite-central1-compute"
  location = "us-central1"
  cluster  = google_container_cluster.buildkite_infra_central1.name

  # total nodes provisioned = node_count * # of AZs
  node_count = 1
  autoscaling {
    min_node_count = 1
    max_node_count = 1
  }
  node_config {
    preemptible  = true
    machine_type = "c2-standard-60"
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
