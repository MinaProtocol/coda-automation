locals {
  netname    = "20190627"
  aws_key_name = "testnet"
}

terraform {
  required_version = "~> 0.12.0"
  backend "s3" {
    key     = "test-net/terraform-20190627.tfstate"
    encrypt = true
    region  = "us-west-2"
    bucket  = "o1labs-terraform-state"
    acl     = "bucket-owner-full-control"
  }
}

provider "aws" {
  region = "us-west-2"
}


######################################################################
# instances

## Seeds
module "us-west-2-seed" {
  source        = "../../modules/coda-node"
  region        = "us-west-2"
  server_count  = 1
  instance_type = "c5.xlarge"
  netname       = "${local.netname}"
  rolename      = "seed"
  key_name      = "${local.aws_key_name}"
}

## Joiners
module "us-west-2-joiner" {
  source        = "../../modules/coda-node"
  region        = "us-west-2"
  server_count  = 4
  instance_type = "c5.xlarge"
  netname       = "${local.netname}"
  rolename      = "joiner"
  key_name      = "${local.aws_key_name}"
}

## Snarkers
module "us-west-2-snarker" {
  source        = "../../modules/coda-node"
  region        = "us-west-2"
  server_count  = 1
  instance_type = "c5.4xlarge"
  netname       = "${local.netname}"
  rolename      = "snarker"
  key_name      = "${local.aws_key_name}"
}

######################################################################
## Proposers

module "us-west-1-proposer" {
  source        = "../../modules/coda-node"
  region        = "us-west-1"
  server_count  = 1
  instance_type = "c5.2xlarge"
  netname       = "${local.netname}"
  rolename      = "proposer"
  key_name      = "${local.aws_key_name}"
}

module "us-west-2-proposer" {
  source        = "../../modules/coda-node"
  region        = "us-west-2"
  server_count  = 1
  instance_type = "c5.2xlarge"
  netname       = "${local.netname}"
  rolename      = "proposer"
  key_name      = "${local.aws_key_name}"
}

module "us-east-1-proposer" {
  source        = "../../modules/coda-node"
  region        = "us-east-1"
  server_count  = 1
  instance_type = "c5.2xlarge"
  netname       = "${local.netname}"
  rolename      = "proposer"
  key_name      = "${local.aws_key_name}"
}

module "us-east-2-proposer" {
  source        = "../../modules/coda-node"
  region        = "us-east-2"
  server_count  = 1
  instance_type = "c5.2xlarge"
  netname       = "${local.netname}"
  rolename      = "proposer"
  key_name      = "${local.aws_key_name}"
}

module "eu-west-1-proposer" {
  source        = "../../modules/coda-node"
  region        = "eu-west-1"
  server_count  = 1
  instance_type = "c5.2xlarge"
  netname       = "${local.netname}"
  rolename      = "proposer"
  key_name      = "${local.aws_key_name}"
}

# module "sa-east-1-proposer" {
#   source        = "../modules/coda-node"
#   region        = "sa-east-1"
#   server_count  = 1
#   instance_type = "c5.2xlarge"
#   netname       = "${local.netname}"
#   rolename      = "proposer"
#  key_name      = "${local.aws_key_name}"
# }

# module "ap-south-1-proposer" {
#   source        = "../modules/coda-node"
#   region        = "ap-south-1"
#   server_count  = 1
#   instance_type = "c5.2xlarge"
#   netname       = "${local.netname}"
#   rolename      = "proposer"
#   public_key    = "${local.public_key}"
#  key_name      = "${local.aws_key_name}"
# }
