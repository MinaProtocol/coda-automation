terraform {
  required_version = "~> 0.12.0"
  backend "s3" {
    key     = "terraform-deploy-test1.tfstate"
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
  testnet_name = "deploy-test1"
  coda_image   = var.coda_image
  seed_region = "us-east1"
  seed_zone = "us-west1-1"
  seed_discovery_keypairs = [
    "CAESQNf7ldToowe604aFXdZ76GqW/XVlDmnXmBT+otorvIekBmBaDWu/6ZwYkZzqfr+3IrEh6FLbHQ3VSmubV9I9Kpc=,CAESIAZgWg1rv+mcGJGc6n6/tyKxIehS2x0N1Uprm1fSPSqX,12D3KooWAFFq2yEQFFzhU5dt64AWqawRuomG9hL8rSmm5vxhAsgr",
    "CAESQKtOnmYHQacRpNvBZDrGLFw/tVB7V4I14Y2xtGcp1sEsEyfcsNoFi7NnUX0T2lQDGQ31KvJRXJ+u/f9JQhJmLsI=,CAESIBMn3LDaBYuzZ1F9E9pUAxkN9SryUVyfrv3/SUISZi7C,12D3KooWB79AmjiywL1kMGeKHizFNQE9naThM2ooHgwFcUzt6Yt1"
  ]
  ledger_config_location = "/home/o1labs/Documents/projects/coda2/genesis_ledgers/phase_three/config.json"
}
variable "coda_image" {
  type = string
  default = "codaprotocol/coda-daemon:0.0.12-beta-feature-gossip-latency-7b555c4"
}