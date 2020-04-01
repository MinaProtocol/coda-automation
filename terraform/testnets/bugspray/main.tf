terraform {
  required_version = "~> 0.12.0"
  backend "s3" {
    key     = "terraform-hangry-lobster.tfstate"
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
  testnet_name = "hangry-lobster"
  coda_image   = var.coda_image
  coda_agent_image = var.coda_agent_image
}

variable "coda_image" {
  type = string
  default = "codaprotocol/coda-daemon:0.0.13-beta-testnet-hangry-lobster-b3b9d23"
}

variable "coda_agent_image" {
  type = string
  default = "codaprotocol/coda-user-agent:0.1.4-bugspray"
}
