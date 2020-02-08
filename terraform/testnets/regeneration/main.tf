terraform {
  required_version = "~> 0.12.0"
  backend "s3" {
    key     = "terraform-regeneration.tfstate"
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
  testnet_name = "regeneration"
  coda_image   = "codaprotocol/coda-daemon:0.0.12-beta-new-genesis-01eca9b"
}