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
  testnet_name    = "regeneration"
  coda_image = "codaprotocol/coda-daemon:0.0.13-beta-master-99d1e1f"
}

provider "google" {
  alias = "google-us-west1"
  project = "o1labs-192920"
  region  = "us-west1"
  zone    = "us-west1-a"
}

module "testnet" {
  providers = {
    google = google.google-us-west1
  }
  source             = "../../modules/kubernetes/testnet"
  cluster_name = "coda-cluster-west"
  cluster_region = "us-west1"
  testnet_name = "regeneration"
  snark_worker_replicas = 1
  snark_worker_fee = 10
  coda_image = local.coda_image
  coda_privkey_pass = "naughty blue worm"
}


# Seed DNS
data "aws_route53_zone" "selected" {
  name = "o1test.net."
}

resource "aws_route53_record" "seed_one" {
  zone_id = "${data.aws_route53_zone.selected.zone_id}"
  name    = "seed-one.${local.testnet_name}.${data.aws_route53_zone.selected.name}"
  type    = "A"
  ttl     = "300"
  records = [module.testnet.seed_one_ip]
}

resource "aws_route53_record" "seed_two" {
  zone_id = "${data.aws_route53_zone.selected.zone_id}"
  name    = "seed-two.${local.testnet_name}.${data.aws_route53_zone.selected.name}"
  type    = "A"
  ttl     = "300"
  records = [module.testnet.seed_two_ip]
}