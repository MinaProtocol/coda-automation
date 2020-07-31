terraform {
  required_version = ">= 0.12.6"
  backend "s3" {
    key     = "terraform-bk-experimental.tfstate"
    encrypt = true
    region  = "us-west-2"
    bucket  = "o1labs-terraform-state"
    acl     = "bucket-owner-full-control"
  }
}

provider "aws" {
  region = "us-west-2"
}

#
# OPTIONAL: input variables
#

variable "cluster_name" {
  type = string

  description = "Name of the cluster to provision"
  default     = "gke-benchmark"
}

variable "agent_vcs_privkey" {
  type = string

  description = "Version control private key for secured repository access"
  default     = ""
}

variable "google_credentials" {
  type = string

  description = "Custom operator Google Cloud Platform access credentials"
  default     = ""
}

variable "k8s_context" {
  type = string

  description = "K8s resource provider context -- generally determined by operating environment"
  default     = "gke_o1labs-192920_us-central1_buildkite-infra-central"
}
