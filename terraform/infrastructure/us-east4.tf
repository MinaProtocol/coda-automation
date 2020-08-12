provider "google" {
  alias   = "google_east4"
  project = "o1labs-192920"
  region  = "us-east4"
}

## Buildkite

resource "google_container_cluster" "buildkite_infra_east4" {
  provider = google.google_east
  name     = "buildkite-infra-east4"
  location = "us-east4"
  min_master_version = "1.15"

  node_locations = [
    "us-east4-a",
    "us-east4-b",
    "us-east4-c"
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

resource "google_container_node_pool" "east4_compute_nodes" {
  provider = google.google_east4
  name       = "buildkite-east4-compute"
  location   = "us-east4"
  cluster    = google_container_cluster.buildkite_infra_east4.name

  # total nodes provisioned = node_count * # of AZs
  node_count = 5
  autoscaling {
    min_node_count = 5
    max_node_count = 5
  }
  node_config {
    preemptible  = true
    machine_type = "c2-standard-16"
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