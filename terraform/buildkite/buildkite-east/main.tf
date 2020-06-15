terraform {
  required_version = ">= 0.12.6"
  backend "s3" {
    key     = "terraform-bk-coda-jobs.tfstate"
    encrypt = true
    region  = "us-west-2"
    bucket  = "o1labs-terraform-state"
    acl     = "bucket-owner-full-control"
  }
}

#
# REQUIRED: input variables -- recommended to express as environment vars (e.g. TF_VAR_***)
#
variable "agent_token" {}

#
# OPTIONAL: input variables
#

variable "cluster_name" {
  type = string

  description = "Name of the cluster to provision"
  default     = "gke-east"
}

# Set to override buildkite agents version control (i.e. github) SSH key
# for private repo access
variable "agent_vcs_privkey" {
  type = string

  description = "version control private key for secured repository access"
  default     = ""
}

# Set to override service account privileges with custom profile
variable "google_credentials" {
  type = string

  description = "custom operator Google Cloud Platform access credentials"
  default     = ""
}

# Determines k8s resource provider context
variable "k8s_provider" {
  type = string

  description = "k8s resource provider -- generally determined by operating environment."
  default     = "minikube"
}

# Local variables for parameterizing cluster topology
locals {
  topology = {
    small = {
      agent = {
        meta  = "size=small"
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
        meta  = "size=large"
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

# Main resource entrypoint
module "buildkite-east" {
  source = "../../modules/kubernetes/buildkite-agent/src"

  google_app_credentials = var.google_credentials
  k8s_cluster_name       = "coda-infra-east"
  k8s_cluster_region     = "us-east1"
  k8s_provider           = var.k8s_provider

  cluster_name      = var.cluster_name

  agent_token       = var.agent_token
  agent_vcs_privkey = var.agent_vcs_privkey
  agent_topology   = local.topology
}
