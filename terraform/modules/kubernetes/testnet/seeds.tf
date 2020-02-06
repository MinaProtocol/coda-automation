# Defaults to the provider project
data "google_project" "project" {
}

module "seed_network" {
  source         = "../../google-cloud/vpc-network"
  network_name   = "${var.testnet_name}-testnet-network"
  network_region = var.seed_region
  subnet_name    = "${var.testnet_name}-testnet-subnet"
}

module "seed_one" {
  source             = "../../google-cloud/coda-seed-node"
  coda_image         = var.coda_image
  project_id         = data.google_project.project.project_id
  subnetwork_project = data.google_project.project.project_id
  subnetwork         = module.seed_network.subnet_link
  network            = module.seed_network.network_link
  instance_name      = "${var.testnet_name}-seed-one"
  zone               = var.seed_zone
  region             = var.seed_region
  client_email       = "1020762690228-compute@developer.gserviceaccount.com"
  discovery_keypair  = var.seed_discovery_keypairs[0]
  seed_peers         = ""
}

module "seed_two" {
  source             = "../../google-cloud/coda-seed-node"
  coda_image         = var.coda_image
  project_id         = data.google_project.project.project_id
  subnetwork_project = data.google_project.project.project_id
  subnetwork         = module.seed_network.subnet_link
  network            = module.seed_network.network_link
  instance_name      = "${var.testnet_name}-seed-two"
  zone               = var.seed_zone
  region             = var.seed_region
  client_email       = "1020762690228-compute@developer.gserviceaccount.com"
  discovery_keypair  = var.seed_discovery_keypairs[1]
  seed_peers         = "-peer /ip4/${module.seed_one.instance_external_ip}/tcp/10002/ipfs/${split(",", module.seed_one.discovery_keypair)[2]}"
}