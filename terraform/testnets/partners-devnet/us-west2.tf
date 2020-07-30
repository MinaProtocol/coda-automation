# provider "google" {
#   alias   = "google-us-west2"
#   project = "o1labs-192920"
#   region  = "us-west2"
#   zone    = "us-west2-a"
# }


# module "testnet_west" {
#   providers = {
#     google = google.google-us-west2
#   }
#   source                = "../../modules/kubernetes/testnet"
#   cluster_name          = "coda-infra-west"
#   cluster_region        = "us-west2"
#   testnet_name          = "partners-devnet"
#   coda_image            = local.coda_image

#   seed_zone = "us-west2-a"
#   seed_region = "us-west2"

#   num_whale_block_producers = 5
#   num_fish_block_producers = 10
#   block_producer_key_pass = "naughty blue worm"
#   block_producer_starting_host_port = 10001

#   snark_worker_replicas = 1
#   snark_worker_fee      = 10
#   snark_worker_public_key = "4vsRCVQZ41uqXfVVfkBNUuNNS7PgSJGdMDNAyKGDdU1WkdxxyxQ7oMdFcjDRf45fiGKkdYKkLPBrE1KnxmyBuvaTW97A5C8XjNSiJmvo9oHa4AwyVsZ3ACaspgQ3EyxQXk6uujaxzvQhbLDx"
#   snark_worker_host_port = 10400
# }

# # Seed DNS
# data "aws_route53_zone" "selected" {
#   name = "o1test.net."
# }

# resource "aws_route53_record" "seed_one" {
#   zone_id = "${data.aws_route53_zone.selected.zone_id}"
#   name    = "seed-one.${local.testnet_name}.${data.aws_route53_zone.selected.name}"
#   type    = "A"
#   ttl     = "300"
#   records = [module.testnet_west.seed_one_ip]
# }

# resource "aws_route53_record" "seed_two" {
#   zone_id = "${data.aws_route53_zone.selected.zone_id}"
#   name    = "seed-two.${local.testnet_name}.${data.aws_route53_zone.selected.name}"
#   type    = "A"
#   ttl     = "300"
#   records = [module.testnet_west.seed_two_ip]
# }
