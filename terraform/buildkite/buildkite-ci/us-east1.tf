data "aws_secretsmanager_secret" "buildkite_agent_token_metadata" {
  name = "buildkite/agent/access-token"
}

data "aws_secretsmanager_secret_version" "buildkite_agent_token" {
  secret_id = "${data.aws_secretsmanager_secret.buildkite_agent_token_metadata.id}"
}

locals {
  topology = {
    small = {
      agent = {
        tags  = "size=small"
        token = data.aws_secretsmanager_secret_version.buildkite_agent_token.secret_string
      }
      resources = {
        limits = {
          cpu    = "2"
          memory = "2G"
        }
      }
      replicaCount = 10
    }
    large = {
      agent = {
        tags  = "size=large"
        token = data.aws_secretsmanager_secret_version.buildkite_agent_token.secret_string
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
  k8s_context          = var.k8s_context

  cluster_name      = var.cluster_name

  agent_vcs_privkey = var.agent_vcs_privkey
  agent_topology    = local.topology
}
