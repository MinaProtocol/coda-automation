provider "google" {
  alias   = "google_west"
  project = "o1labs-192920"
  region  = "us-west1"
}

resource "google_container_cluster" "buildkite_cluster_west" {
  provider = google.google_west
  name     = "buildkite-infra-west"
  location = "us-west1"
  min_master_version = "1.15"

  node_locations = [
    "us-west1-a"
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

resource "google_container_node_pool" "west_primary_nodes" {
  provider = google.google_west
  name       = "buildkite-infra-west"
  location   = "us-west1"
  cluster    = google_container_cluster.buildkite_cluster_west.name
  node_count = 12
  autoscaling {
    min_node_count = 0
    max_node_count = 12
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