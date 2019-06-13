locals {
  netname    = "20190613"
  aws_key_name = "testnet"
}

terraform {
  required_version = "~> 0.12.0"
  backend "s3" {
    key     = "test-net/terraform-20190613.tfstate"
    encrypt = true
    region  = "us-west-2"
    bucket  = "o1labs-terraform-state"
    acl     = "bucket-owner-full-control"
  }
}

provider "aws" {
  region = "us-west-2"
}

# output "elasticsearch-endpoint" {
#   value = "${module.elasticsearch.endpoint}"
# }

# output "kibana-endpoint" {
#   value = "${module.elasticsearch.kibana_endpoint}"
# }


######################################################################
#   Additional IP Addresses to whitelist are being
#   retrieved from AWS Secrets Manager, if they are not
#   present in your AWS Account, terraform will fail with:
#   "Secrets Manager Secret "testnet/elasticsearch/whitelist_ips" not found"
#
# # Console Link: https://us-west-2.console.aws.amazon.com/secretsmanager/home
# #
# data "aws_secretsmanager_secret" "elasticsearch_additional_ips" {
#   name = "testnet/elasticsearch/whitelist_ips"
# }

# data "aws_secretsmanager_secret_version" "selected" {
#   secret_id = data.aws_secretsmanager_secret.elasticsearch_additional_ips.id
# }

#####################################################################
# Elastic Search
# module "elasticsearch" {
#   source                         = "../modules/elasticsearch"
#   domain_name                    = "coda-net"
#   domain_prefix = "testnet-20190613-"
#   management_public_ip_addresses = compact(concat(
#     jsondecode(data.aws_secretsmanager_secret_version.selected.secret_string)["elasticsearch_whitelist_ips"],
#     module.us-west-2-seed.public_ip,
#     module.us-west-2-snarker.public_ip,
#     module.us-west-1-proposer.public_ip,
#     module.us-west-2-proposer.public_ip,
#     module.us-east-1-proposer.public_ip,
#     module.us-east-2-proposer.public_ip,
#     module.eu-west-1-proposer.public_ip,
#   ))
#   instance_count                 = 1
#   instance_type                  = "m4.2xlarge.elasticsearch"
#   es_zone_awareness              = false
#   ebs_volume_size                = 40
# }


######################################################################
# instances

## Seeds
module "us-west-2-seed" {
  source        = "../modules/coda-node"
  region        = "us-west-2"
  server_count  = 1
  instance_type = "c5.xlarge"
  netname       = "${local.netname}"
  rolename      = "seed"
  key_name      = "${local.aws_key_name}"
}

## Joiners
module "us-west-2-joiner" {
  source        = "../modules/coda-node"
  region        = "us-west-2"
  server_count  = 1
  instance_type = "c5.xlarge"
  netname       = "${local.netname}"
  rolename      = "joiner"
  key_name      = "${local.aws_key_name}"
}

## Snarkers
module "us-west-2-snarker" {
  source        = "../modules/coda-node"
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
  source        = "../modules/coda-node"
  region        = "us-west-1"
  server_count  = 1
  instance_type = "c5.2xlarge"
  netname       = "${local.netname}"
  rolename      = "proposer"
  key_name      = "${local.aws_key_name}"
}

module "us-west-2-proposer" {
  source        = "../modules/coda-node"
  region        = "us-west-2"
  server_count  = 1
  instance_type = "c5.2xlarge"
  netname       = "${local.netname}"
  rolename      = "proposer"
  key_name      = "${local.aws_key_name}"
}

module "us-east-1-proposer" {
  source        = "../modules/coda-node"
  region        = "us-east-1"
  server_count  = 1
  instance_type = "c5.2xlarge"
  netname       = "${local.netname}"
  rolename      = "proposer"
  key_name      = "${local.aws_key_name}"
}

module "us-east-2-proposer" {
  source        = "../modules/coda-node"
  region        = "us-east-2"
  server_count  = 1
  instance_type = "c5.2xlarge"
  netname       = "${local.netname}"
  rolename      = "proposer"
  key_name      = "${local.aws_key_name}"
}

module "eu-west-1-proposer" {
  source        = "../modules/coda-node"
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
