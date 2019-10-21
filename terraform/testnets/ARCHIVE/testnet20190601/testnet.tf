locals {
  netname    = "20190601"                                                                                                                                                                                                                                                                                                                                                                                      # see also backend key
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDHWTr1IZY2c4+j7KldT59folvsdpJjTGC6ULBDD7IyUqGDYhxv2X4UeO17V1ENeZLvABaiIPtw6R4qRMgoOXEVOZsNljqpPwLMK3cY3JeM/tL9XPQXuZQrpRsFdYUOeNI9OyG34gfdHpbn24SIEGrDjqWg6kKtwJ916fB6f7JNxBDLP5cJQhP7z57Km3V6+YcaRIkshkrfaBGKVKp58aibbNOPn1B4vMWSQcPyC50xlnUT5rnKiRUClT1nP0OTgxL9L6FWADKow83wJ/95RA5evBHjZuE7Qz1U3sVLx0lzWBgZRC40Nz+77W3/kQvceCWe8WCuavArH/q5It5fOzsv testnet"
}

terraform {
  required_version = "~> 0.12.0"
  backend "s3" {
    key     = "test-net/terraform-20190601.tfstate"
    encrypt = true
    region  = "us-west-2"
    bucket  = "o1labs-terraform-state"
    acl     = "bucket-owner-full-control"
  }
}

provider "aws" {
  region = "us-west-2"
}

output "elasticsearch-endpoint" {
  value = "${module.elasticsearch.endpoint}"
}

output "kibana-endpoint" {
  value = "${module.elasticsearch.kibana_endpoint}"
}


######################################################################
#   Additional IP Addresses to whitelist are being
#   retrieved from AWS Secrets Manager, if they are not
#   present in your AWS Account, terraform will fail with:
#   "Secrets Manager Secret "testent/elasticsearch/whitelist_ips" not found"
#
# Console Link: https://us-west-2.console.aws.amazon.com/secretsmanager/home
#
data "aws_secretsmanager_secret" "elasticsearch_additional_ips" {
  name = "testnet/elasticsearch/whitelist_ips"
}

data "aws_secretsmanager_secret_version" "selected" {
  secret_id = data.aws_secretsmanager_secret.elasticsearch_additional_ips.id
}

#####################################################################
# Elastic Search
module "elasticsearch" {
  source                         = "../../modules/elasticsearch"
  domain_name                    = "coda-net"
  domain_prefix = "testnet-${local.netname}-"
  management_public_ip_addresses = compact(concat(
    jsondecode(data.aws_secretsmanager_secret_version.selected.secret_string)["elasticsearch_whitelist_ips"],
    module.us-west-2-seed.public_ip,
    module.us-west-2-snarker.public_ip,
    module.us-west-1-proposer.public_ip,
#    module.us-west-2-proposer.public_ip
  ))
  instance_count                 = 1
  instance_type                  = "m4.2xlarge.elasticsearch"
  es_zone_awareness              = false
  ebs_volume_size                = 40
  create_iam_service_linked_role = true
}

# Save the ElasticSearch endpoint to AWS Secrets Manager for use in deployment
resource "aws_secretsmanager_secret" "elastic_endpoint" {
  name = "testnet/${local.netname}/elasticsearch/endpoint"
}

resource "aws_secretsmanager_secret_version" "elastic_endpoint" {
  secret_id     = "${aws_secretsmanager_secret.elastic_endpoint.id}"
  secret_string = "${module.elasticsearch.endpoint}"
}

# Save the Kibana endpoint to AWS Secrets Manager for use in deployment
resource "aws_secretsmanager_secret" "kibana_endpoint" {
  name = "testnet/${local.netname}/kibana/endpoint"
}

resource "aws_secretsmanager_secret_version" "kibana_endpoint" {
  secret_id     = "${aws_secretsmanager_secret.kibana_endpoint.id}"
  secret_string =  "${module.elasticsearch.kibana_endpoint}"
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
  public_key    = "${local.public_key}"
}

## Snarkers
module "us-west-2-snarker" {
  source        = "../../modules/coda-node"
  region        = "us-west-2"
  server_count  = 1
  instance_type = "c5.4xlarge"
  netname       = "${local.netname}"
  rolename      = "snarker"
  public_key    = "${local.public_key}"
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
  public_key    = "${local.public_key}"
}

# module "us-west-2-proposer" {
#   source        = "../modules/coda-node"
#   region        = "us-west-2"
#   server_count  = 5
#   instance_type = "c5.2xlarge"
#   netname       = "${local.netname}"
#   rolename      = "proposer"
#   public_key    = "${local.public_key}"
# }

# module "us-east-1-proposer" {
#   source        = "../modules/coda-node"
#   region        = "us-east-1"
#   server_count  = 1
#   instance_type = "c5.2xlarge"
#   netname       = "${local.netname}"
#   rolename      = "proposer"
#   public_key    = "${local.public_key}"
# }
# module "eu-west-1-proposer" {
#   source        = "../modules/coda-node"
#   region        = "eu-west-1"
#   server_count  = 1
#   instance_type = "c5.2xlarge"
#   netname       = "${local.netname}"
#   rolename      = "proposer"
#   public_key    = "${local.public_key}"
# }

# module "sa-east-1-proposer" {
#   source        = "../modules/coda-node"
#   region        = "sa-east-1"
#   server_count  = 1
#   instance_type = "c5.2xlarge"
#   netname       = "${local.netname}"
#   rolename      = "proposer"
#   public_key    = "${local.public_key}"
# }

# module "ap-south-1-proposer" {
#   source        = "../modules/coda-node"
#   region        = "ap-south-1"
#   server_count  = 1
#   instance_type = "c5.2xlarge"
#   netname       = "${local.netname}"
#   rolename      = "proposer"
#   public_key    = "${local.public_key}"
# }
