terraform {
  required_version = ">= 0.12.6"
  backend "s3" {
    key     = "terraform-bk-coda-ci.tfstate"
    encrypt = true
    region  = "us-west-2"
    bucket  = "o1labs-terraform-state"
    acl     = "bucket-owner-full-control"
  }
}

provider "aws" {
  region = "us-west-2"
}

data "aws_secretsmanager_secret" "buildkite_agent_token_metadata" {
  name = "buildkite/agent/access-token"
}

data "aws_secretsmanager_secret_version" "buildkite_agent_token" {
  secret_id = "${data.aws_secretsmanager_secret.buildkite_agent_token_metadata.id}"
}

#
# OPTIONAL: input variables -- recommended to express as environment vars (e.g. TF_VAR_***)
#

variable "cluster_name" {
  type = string

  description = "Name of the cluster to provision"
  default     = "gke-west"
}

variable "google_credentials" {
  type = string

  description = "Custom operator Google Cloud Platform access credentials"
  default     = ""
}

variable "agent_vcs_privkey" {
  type = string

  description = "Version control private key for secured repository access"
  default     = ""
}

variable "k8s_context" {
  type = string

  description = "K8s resource provider context -- generally determined by operating environment"
  default     = "gke_o1labs-192920_us-west1_buildkite-infra-west"
}
