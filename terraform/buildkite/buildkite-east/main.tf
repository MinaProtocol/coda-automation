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

variable "agent_vcs_privkey" {
  type = string

  description = "version control private key for secured repository access"
  default     = ""
}

variable "google_credentials" {
  type = string

  description = "custom operator Google Cloud Platform access credentials"
  default     = ""
}

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
    xxlarge = {
      agent = {
        tags  = "size=xxlarge"
        token = var.agent_token
      }
      resources = {
        limits = {
          cpu    = "14"
          memory = "10G"
        }
      }
      replicaCount = 2
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
