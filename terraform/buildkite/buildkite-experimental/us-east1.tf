data "aws_secretsmanager_secret" "buildkite_agent_token_metadata" {
  name = "buildkite/agent/access-token"
}

data "aws_secretsmanager_secret_version" "buildkite_agent_token" {
  secret_id = "${data.aws_secretsmanager_secret.buildkite_agent_token_metadata.id}"
}

locals {
  experimental_topology = {
    experimental = {
      agent = {
        tags  = "size=experimental"
        token = data.aws_secretsmanager_secret_version.buildkite_agent_token.secret_string
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
  k8s_context           = var.k8s_context

  cluster_name      = var.cluster_name

  agent_vcs_privkey = var.agent_vcs_privkey
  agent_topology    = local.experimental_topology
}
