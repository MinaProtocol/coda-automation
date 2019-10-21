locals {
  netname      = "new-role-test"
  aws_key_name = "testnet"
  coda_repo    = "stable"
  coda_version = "209793-release-0.0.5-beta-7a5ecfdf-PV86bf40d3"
}

terraform {
  required_version = "~> 0.12.0"
  backend "s3" {
    key     = "test-net/terraform-new-role-test.tfstate"
    encrypt = true
    region  = "us-west-2"
    bucket  = "o1labs-terraform-state"
    acl     = "bucket-owner-full-control"
  }
}

provider "aws" {
  region = "us-west-2"
}

## Seed
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
  records = concat(module.us-west-2-seed.public_ip, module.us-west-2-seedjoiner.public_ip, module.us-east-1-seedjoiner.public_ip)
}

######################################################################
## seedjoiners
module "us-west-2-seedjoiner" {
  source        = "../../modules/coda-node"
  region        = "us-west-2"
  server_count  = 1
  instance_type = "c5.2xlarge"
  netname       = "${local.netname}"
  rolename      = "seedjoiner"
  key_name      = "${local.aws_key_name}"
  public_key    = ""
  coda_repo     = "${local.coda_repo}"
  coda_version  = "${local.coda_version}"
}

 module "us-east-1-seedjoiner" {
  source        = "../../modules/coda-node"
  region        = "us-east-1"
  server_count  = 1
  instance_type = "c5.2xlarge"
  netname       = "${local.netname}"
  rolename      = "seedjoiner"
  key_name      = "${local.aws_key_name}"
  public_key    = ""
  coda_repo     = "${local.coda_repo}"
  coda_version  = "${local.coda_version}"
}

######################################################################
## archive
 module "us-east-1-archive" {
  source        = "../../modules/coda-node"
  region        = "us-east-1"
  server_count  = 1
  instance_type = "c5.2xlarge"
  netname       = "${local.netname}"
  rolename      = "archive"
  key_name      = "${local.aws_key_name}"
  public_key    = ""
  coda_repo     = "${local.coda_repo}"
  coda_version  = "${local.coda_version}"
}

######################################################################
## snarkercoordinators
module "us-west-2-snarkcoordinator" {
  source        = "../../modules/coda-node"
  region        = "us-west-2"
  server_count  = 1
  instance_type = "c5.9xlarge"
  netname       = "${local.netname}"
  rolename      = "snarkcoordinator"
  key_name      = "${local.aws_key_name}"
  public_key    = ""
  coda_repo     = "${local.coda_repo}"
  coda_version  = "${local.coda_version}"
}

######################################################################
## blockproducers

 module "us-west-1-blockproducer" {
  source        = "../../modules/coda-node"
  region        = "us-west-1"
  server_count  = 3
  instance_type = "c5.2xlarge"
  netname       = "${local.netname}"
  rolename      = "blockproducer"
  key_name      = "${local.aws_key_name}"
  public_key    = ""
  coda_repo     = "${local.coda_repo}"
  coda_version  = "${local.coda_version}"
}

 module "us-west-2-blockproducer" {
  source        = "../../modules/coda-node"
  region        = "us-west-2"
  server_count  = 2
  instance_type = "c5.2xlarge"
  netname       = "${local.netname}"
  rolename      = "blockproducer"
  key_name      = "${local.aws_key_name}"
  public_key    = ""
  coda_repo     = "${local.coda_repo}"
  coda_version  = "${local.coda_version}"
}