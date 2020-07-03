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
  default     = "gke-experimental"
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

variable "k8s_context" {
  type = string

  description = "k8s resource provider context -- generally determined by operating environment"
  default     = "minikube"
}
