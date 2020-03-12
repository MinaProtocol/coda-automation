terraform {
  required_version = "~> 0.12.0"
  backend "s3" {
    key     = "terraform-gerald.tfstate"
    encrypt = true
    region  = "us-west-2"
    bucket  = "o1labs-terraform-state"
    acl     = "bucket-owner-full-control"
  }
}

provider "aws" {
  region = "us-west-2"
}

locals {
  testnet_name = "gerald"
  coda_image   = var.coda_image
  coda_agent_image = var.coda_agent_image
}

variable "coda_image" {
  type = string
  default = "codaprotocol/coda-daemon:0.0.12-beta-qa-net-params-1c42d65"
}

variable "coda_agent_image" {
  type = string
  default = "codaprotocol/coda-user-agent:0.1.3-gerald"
}
