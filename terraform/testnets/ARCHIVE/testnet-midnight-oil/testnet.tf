locals {
  netname      = "midnight-oil"
  aws_key_name = "testnet"
  coda_repo    = "stable"
  coda_version = "199878-release-0.0.4-beta-50abf375-PV4a1e9b4a"
}

terraform {
  required_version = "~> 0.12.0"
  backend "s3" {
    key     = "test-net/terraform-midnight-oil.tfstate"
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

# resource "aws_route53_record" "multiseed" {
#   zone_id = "${data.aws_route53_zone.selected.zone_id}"
#   name    = "multiseed-${local.netname}.${data.aws_route53_zone.selected.name}"
#   type    = "A"
#   ttl     = "300"
#   records = concat(module.us-west-2-seed.public_ip, module.us-west-2-joiner.public_ip, module.us-east-1-joiner.public_ip)
# }


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

module "us-west-2-proposer" {
  source        = "../../modules/coda-node"
  region        = "us-west-2"
  server_count  = 5
  instance_type = "c5.2xlarge"
  custom_ami    = "ami-0f921d4caacd8d746"
  netname       = "${local.netname}"
  rolename      = "proposer"
  key_name      = "${local.aws_key_name}"
  public_key    = ""
  coda_repo     = "${local.coda_repo}"
  coda_version  = "${local.coda_version}"
}
