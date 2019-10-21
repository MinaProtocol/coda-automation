locals {
  netname      = "does-not-compute"
  aws_key_name = "testnet"
  coda_repo    = "stable"
  coda_version = "208618-release-0.0.5-beta-41c5ceec-PV6d572417"
}

terraform {
  required_version = "~> 0.12.0"
  backend "s3" {
    key     = "test-net/terraform-does-not-compute.tfstate"
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
  instance_type = "c5.2xlarge"
  netname       = "${local.netname}"
  rolename      = "seed"
  key_name      = "${local.aws_key_name}"
  public_key    = ""
  coda_repo     = "${local.coda_repo}"
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

resource "aws_route53_record" "multiseed" {
  zone_id = "${data.aws_route53_zone.selected.zone_id}"
  name    = "multiseed-${local.netname}.${data.aws_route53_zone.selected.name}"
  type    = "A"
  ttl     = "300"
  records = concat(module.us-west-2-seed.public_ip, module.us-west-2-joiner.public_ip, module.us-east-1-joiner.public_ip)
}

######################################################################
## Joiners
module "us-west-2-joiner" {
  source        = "../../modules/coda-node"
  region        = "us-west-2"
  server_count  = 1
  instance_type = "c5.2xlarge"
  netname       = "${local.netname}"
  rolename      = "joiner"
  key_name      = "${local.aws_key_name}"
  public_key    = ""
  coda_repo     = "${local.coda_repo}"
  coda_version  = "${local.coda_version}"
}


module "us-east-1-joiner" {
  source        = "../../modules/coda-node"
  region        = "us-east-1"
  server_count  = 1
  instance_type = "c5.2xlarge"
  netname       = "${local.netname}"
  rolename      = "joiner"
  key_name      = "${local.aws_key_name}"
  public_key    = ""
  coda_repo     = "${local.coda_repo}"
  coda_version  = "${local.coda_version}"
}

######################################################################
## Snarkers
module "us-west-2-snarker" {
  source        = "../../modules/coda-node"
  region        = "us-west-2"
  server_count  = 1
  instance_type = "c5.9xlarge"
  netname       = "${local.netname}"
  rolename      = "snarker"
  key_name      = "${local.aws_key_name}"
  public_key    = ""
  coda_repo     = "${local.coda_repo}"
  coda_version  = "${local.coda_version}"
}

######################################################################
## Proposers

module "us-west-1-proposer" {
  source        = "../../modules/coda-node"
  region        = "us-west-1"
  server_count  = 3
  instance_type = "c5.2xlarge"
  netname       = "${local.netname}"
  rolename      = "proposer"
  key_name      = "${local.aws_key_name}"
  public_key    = ""
  coda_repo     = "${local.coda_repo}"
  coda_version  = "${local.coda_version}"
}

module "us-west-2-proposer" {
  source        = "../../modules/coda-node"
  region        = "us-west-2"
  server_count  = 2
  instance_type = "c5.2xlarge"
  netname       = "${local.netname}"
  rolename      = "proposer"
  key_name      = "${local.aws_key_name}"
  public_key    = ""
  coda_repo     = "${local.coda_repo}"
  coda_version  = "${local.coda_version}"
}
