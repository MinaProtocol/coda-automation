locals {
  netname      = "medium-rare"
  aws_key_name = "testnet"
  coda_repo    = "release"
  coda_version = "0.0.3-beta-9def15a5"
}

terraform {
  required_version = "~> 0.12.0"
  backend "s3" {
    key     = "test-net/terraform-medium-rare.tfstate"
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
  custom_ami = "ami-09d31fc66dcb58522"
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
  custom_ami    = "ami-09d31fc66dcb58522"
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
  custom_ami    = "ami-0cfac3931b2a799d1"
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
  instance_type = "c5.24xlarge"
  custom_ami    = "ami-09d31fc66dcb58522"
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
  server_count  = 1
  instance_type = "c5.2xlarge"
  custom_ami    = "ami-0f921d4caacd8d746"
  netname       = "${local.netname}"
  rolename      = "proposer"
  key_name      = "${local.aws_key_name}"
  public_key    = ""
  coda_repo     = "${local.coda_repo}"
  coda_version  = "${local.coda_version}"
}
