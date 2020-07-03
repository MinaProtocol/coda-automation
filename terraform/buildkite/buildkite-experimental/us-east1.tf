locals {
  experimental_topology = {
    experimental = {
      agent = {
        tags  = "size=experimental"
        token = var.agent_token
      }
      resources = {
        limits = {
          cpu    = "15"
          memory = "10G"
        }
      }
      replicaCount = 1
    }
  }
}

module "buildkite-ci-compute" {
  source = "../../modules/kubernetes/buildkite-agent"

  google_app_credentials = var.google_credentials
  k8s_cluster_name       = "buildkite-infra-east"
  k8s_cluster_region     = "us-east1"
  k8s_provider           = var.k8s_provider

  cluster_name      = "bk-benchmarking"

  agent_token       = var.agent_token
  agent_vcs_privkey = var.agent_vcs_privkey
  agent_topology    = local.experimental_topology
}
