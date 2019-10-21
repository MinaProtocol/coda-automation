locals {
  netname      = "strawberry-milkshake"
  aws_key_name = "testnet"
  coda_version = "0.0.1-release-beta-9fa6e5ec"
}

terraform {
  required_version = "~> 0.12.0"
  backend "s3" {
    key     = "test-net/terraform-strawberry-milkshake.tfstate"
    encrypt = true
    region  = "us-west-2"
    bucket  = "o1labs-terraform-state"
    acl     = "bucket-owner-full-control"
  }
}

provider "aws" {
  region = "us-west-2"
}

## Seeds
module "us-west-2-seed" {
  source        = "../../modules/coda-node"
  region        = "us-west-2"
  server_count  = 1
  instance_type = "c5.xlarge"
  netname       = "${local.netname}"
  rolename      = "seed"
  key_name      = "${local.aws_key_name}"
  public_key    = ""
  coda_version  = "${local.coda_version}"
}

## Seed Hostname

data "aws_route53_zone" "selected" {
  name = "o1test.net."
}

resource "aws_route53_record" "netname" {
  zone_id = "${data.aws_route53_zone.selected.zone_id}"
  name    = "${local.netname}.${data.aws_route53_zone.selected.name}"
  type    = "A"
  ttl     = "300"
  records = module.us-west-2-seed.public_ip
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
  public_key    = ""
  coda_version  = "${local.coda_version}"
}

######################################################################
## Proposers

module "us-west-2-proposer" {
  source        = "../../modules/coda-node"
  region        = "us-west-2"
  server_count  = 3
  instance_type = "c5.2xlarge"
  netname       = "${local.netname}"
  rolename      = "proposer"
  key_name      = "${local.aws_key_name}"
  public_key    = ""
  coda_version  = "${local.coda_version}"
}


module "us-west-1-proposer" {
  source        = "../../modules/coda-node"
  region        = "us-west-1"
  server_count  = 3
  instance_type = "c5.2xlarge"
  netname       = "${local.netname}"
  rolename      = "proposer"
  key_name      = "${local.aws_key_name}"
  public_key    = ""
  coda_version  = "${local.coda_version}"
}
