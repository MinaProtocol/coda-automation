terraform {
    required_version = "~> 0.12.0"
    backend "s3" {
        key     = "terraform-bkexperimental.tfstate"
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
    type    = string

    description = "k8s resource provider -- generally determined by operating environment."
    default = "minikube"
}

# Main resource entrypoint
module "buildkite_east" {
    source                  = "../../modules/kubernetes/buildkite-agent"

    google_app_credentials  =   var.google_credentials
    k8s_cluster_name        = "coda-infra-east"
    k8s_cluster_region      = "us-east1"
    k8s_provider            = var.k8s_provider

    cluster_name            = "experimental"
    cluster_namespace       = "experimental"
    agent_token             = var.agent_token
    agent_vcs_privkey       = var.agent_vcs_privkey
    agent_meta              = "queue=default,queue=coda"
    num_agents              = 10
}
