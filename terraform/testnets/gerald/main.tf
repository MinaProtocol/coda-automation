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
}
variable "coda_image" {
  type = string
  default = "codaprotocol/coda-daemon:0.0.12-beta-qa-net-params-f91d3d5"
}
