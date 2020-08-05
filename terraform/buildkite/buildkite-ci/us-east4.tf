locals {
  east4_compute_topology = {
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
      replicaCount = 20
    }

    medium = {
      agent = {
        tags  = "size=medium"
        token = data.aws_secretsmanager_secret_version.buildkite_agent_token.secret_string
      }
      resources = {
        limits = {
          cpu    = "4"
          memory = "4G"
        }
      }
      replicaCount = 12
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
      replicaCount = 8
    }

    xlarge = {
      agent = {
        tags  = "size=xlarge"
        token = data.aws_secretsmanager_secret_version.buildkite_agent_token.secret_string
      }
      resources = {
        limits = {
          cpu    = "15.5"
          memory = "16G"
        }
      }
      replicaCount = 4
    }
  }
}

module "buildkite-east4-compute" {
  source = "../../modules/kubernetes/buildkite-agent"

  k8s_context             = "gke_o1labs-192920_us-east4_buildkite-infra-east4"
  cluster_name            = "gke-east4"

  google_app_credentials  = var.google_credentials

  agent_vcs_privkey       = var.agent_vcs_privkey
  agent_topology          = local.east4_compute_topology
}
