# K8s Cluster Vars

variable "cluster_name" {
  type = string
}

variable "cluster_region" {
  type = string
}

# Global Vars

variable "coda_image" {
  type    = string
  default = "codaprotocol/coda-daemon:0.0.13-beta-master-99d1e1f"
}

variable "testnet_name" {
  type    = string
  default = "coda-testnet"
}

variable "additional_seed_peers" {
  type    = list
  default = []
}

# Seed Vars

variable "seed_region" {
  type    = string
  default = "us-west1"
}

variable "seed_zone" {
  type    = string
  default = "us-west1-a"
}

variable "seed_discovery_keypairs" {
  type = list
  default = [
    "23jhTeLbLKJSM9f3xgbG1M6QRHJksFtjP9VUNUmQ9fq3urSovGVS25k8LLn8mgdyKcYDSteRcdZiNvXXXAvCUnST6oufs,4XTTMESM7AkSo5yfxJFBpLr65wdVt8dfuQTuhgQgtnADryQwP,12D3KooWP7fTKbyiUcYJGajQDpCFo2rDexgTHFJTxCH8jvcL1eAH",
    "23jhTbijdCA9zioRbv7HboRs7F8qZL59N5GQvGzhfB3MrS5qNrQK5fEdWyB5wno9srsDFNRc4FaNUDCEnzJGHG9XX6iSe,4XTTMBUfbSrzTGiKVp8mhZCuE9nDwj3USx3WL2YmFpP4zM2DG,12D3KooWL9ywbiXNfMBqnUKHSB1Q1BaHFNUzppu6JLMVn9TTPFSA"
  ]
}

# Block Producer Vars

variable "block_producer_key_pass" {
  type = string
}

variable "block_producer_starting_host_port" {
  type    = number
  default = 10000
}

variable "num_whale_block_producers" {
  type    = number
  default = 3
}

variable "num_fish_block_producers" {
  type    = number
  default = 5
}

variable "fish_block_producer_label_offset" {
  type = number
  default = 0
}

# Snark Worker Vars

variable "snark_worker_replicas" {
  type    = number
  default = 1
}

variable "snark_worker_fee" {
  type    = number
  default = 10
}

variable "snark_worker_public_key" {
  type    = string
  default = "4vsRCVadXwWMSGA9q81reJRX3BZ5ZKRtgZU7PtGsNq11w2V9tUNf4urZAGncZLUiP4SfWqur7AZsyhJKD41Ke7rJJ8yDibL41ePBeATLUnwNtMTojPDeiBfvTfgHzbAVFktD65vzxMNCvvAJ"
}

variable "snark_worker_host_port" {
  type    = number
  default = 10400
}

