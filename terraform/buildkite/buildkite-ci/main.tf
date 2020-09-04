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

data "aws_secretsmanager_secret" "buildkite_agent_apitoken_metadata" {
  name = "buildkite/agent/api-token"
}

data "aws_secretsmanager_secret_version" "buildkite_agent_apitoken" {
  secret_id = "${data.aws_secretsmanager_secret.buildkite_agent_apitoken_metadata.id}"
}

# Monitoring : Buildkite GraphQL exporter

locals {
  exporter_vars = {
    exporter = {
        buildkiteApiKey = data.aws_secretsmanager_secret_version.buildkite_agent_apitoken.secret_string
    }
  }
}

provider helm {
  kubernetes {
    config_context  = "gke_o1labs-192920_us-east1_buildkite-infra-east1"
  }
}

resource "helm_release" "buildkite_graphql_exporter" {
  name      = "buildkite-coda-exporter"
  chart     = "../../../helm/buildkite-exporter"
  namespace = "default"
  values = [
    yamlencode(local.exporter_vars)
  ]
  wait       = true
}

#
# OPTIONAL: input variables -- recommended to express as environment vars (e.g. TF_VAR_***)
#

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
