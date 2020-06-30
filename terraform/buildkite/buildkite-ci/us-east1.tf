locals {
  topology = {
    small = {
      agent = {
        tags  = "size=small"
        token = var.agent_token
      }
      resources = {
        limits = {
          cpu    = "2"
          memory = "2G"
        }
      }
      replicaCount = 5
    }
    large = {
      agent = {
        tags  = "size=large"
        token = var.agent_token
      }
      resources = {
        limits = {
          cpu    = "8"
          memory = "8G"
        }
      }
      replicaCount = 5
    }
  }
}

module "buildkite-east" {
  source = "../../modules/kubernetes/buildkite-agent"

  google_app_credentials = var.google_credentials
  k8s_cluster_name       = "coda-infra-east"
  k8s_cluster_region     = "us-east1"
  k8s_provider           = var.k8s_provider

  cluster_name      = var.cluster_name

  agent_token       = var.agent_token
  agent_vcs_privkey = var.agent_vcs_privkey
  agent_topology    = local.topology
}


