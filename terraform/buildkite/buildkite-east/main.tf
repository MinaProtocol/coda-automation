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

# Required input variables -- recommended to express as environment vars (e.g. TF_VAR_***)
variable "agent_token" {}
variable "agent_vcs_privkey" {}
variable "google_credentials" {}

# Determines k8s resource provider context
variable "k8s_provider" {
  type = string

  description = "k8s resource provider -- generally determined by operating environment."
  default     = "minikube"
}

# Local variables for parameterizing cluster topology
# TODO: Make use of for_each expression to parameterize module build
# once available (see: https://www.hashicorp.com/blog/hashicorp-terraform-0-12-preview-for-and-for-each/)
locals {
  cluster_types = {
    small = {
      name = "small"
      resources = {
        limits = {
          cpu    = "100m"
          memory = "1G"
        }
      }
      count = 1
    }
    large = {
      name = "large"
      resources = {
        limits = {
          cpu    = "500m"
          memory = "5G"
        }
      }
      count = 1
    }
  }
}

# Main resource entrypoint
module "buildkite-east-small" {
  source = "../../modules/kubernetes/buildkite-agent/src"

  google_app_credentials = var.google_credentials
  k8s_cluster_name       = "coda-infra-east"
  k8s_cluster_region     = "us-east1"
  k8s_provider           = var.k8s_provider

  cluster_name      = "buildkite-east-small"
  cluster_namespace = "bk-${local.cluster_types.small.name}"

  agent_token       = var.agent_token
  agent_vcs_privkey = var.agent_vcs_privkey
  agent_meta        = "cluster=buildkite-east,size=${local.cluster_types.small.name},queue=default"
  num_agents        = local.cluster_types.small.count
  agent_resources   = local.cluster_types.small.resources
}

module "buildkite-east-large" {
  source = "../../modules/kubernetes/buildkite-agent/src"

  google_app_credentials = var.google_credentials
  k8s_cluster_name       = "coda-infra-east"
  k8s_cluster_region     = "us-east1"
  k8s_provider           = var.k8s_provider

  cluster_name      = "buildkite-east-large"
  cluster_namespace = "bk-${local.cluster_types.large.name}"

  agent_token       = var.agent_token
  agent_vcs_privkey = var.agent_vcs_privkey
  agent_meta        = "cluster=buildkite-east,size=${local.cluster_types.large.name},queue=default"
  num_agents        = local.cluster_types.large.count
  agent_resources   = local.cluster_types.large.resources
}
