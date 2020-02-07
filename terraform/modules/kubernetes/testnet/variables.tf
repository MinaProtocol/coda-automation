variable "cluster_name" {
  type    = string
}

variable "cluster_region" {
  type    = string
}

variable "testnet_name" {
  type    = string
  default = "coda-testnet"
}

variable "seed_region" {
  type    = string
  default = "us-west1"
}

variable "seed_zone" {
  type    = string
  default = "us-west1-a"
}

variable "seed_discovery_keypairs" {
  type    = list
  default = [
    "23jhTeLbLKJSM9f3xgbG1M6QRHJksFtjP9VUNUmQ9fq3urSovGVS25k8LLn8mgdyKcYDSteRcdZiNvXXXAvCUnST6oufs,4XTTMESM7AkSo5yfxJFBpLr65wdVt8dfuQTuhgQgtnADryQwP,12D3KooWP7fTKbyiUcYJGajQDpCFo2rDexgTHFJTxCH8jvcL1eAH",
    "23jhTbijdCA9zioRbv7HboRs7F8qZL59N5GQvGzhfB3MrS5qNrQK5fEdWyB5wno9srsDFNRc4FaNUDCEnzJGHG9XX6iSe,4XTTMBUfbSrzTGiKVp8mhZCuE9nDwj3USx3WL2YmFpP4zM2DG,12D3KooWL9ywbiXNfMBqnUKHSB1Q1BaHFNUzppu6JLMVn9TTPFSA" 
  ]
}

variable "snark_worker_replicas" {
  type    = number
  default = 1
}

variable "snark_worker_fee" {
  type    = number
  default = 10
}

variable "snark_worker_key" {
  type    = string
  default = "4vsRCVadXwWMSGA9q81reJRX3BZ5ZKRtgZU7PtGsNq11w2V9tUNf4urZAGncZLUiP4SfWqur7AZsyhJKD41Ke7rJJ8yDibL41ePBeATLUnwNtMTojPDeiBfvTfgHzbAVFktD65vzxMNCvvAJ"
}

variable "coda_image" {
  type    = string
  default = "codaprotocol/coda-daemon:0.0.13-beta-master-99d1e1f"
}

variable "coda_helm_repo" {
  type = string 
  default = "https://raw.githubusercontent.com/CodaProtocol/coda-automation/testnet-helm/helm/releases"
}

variable "testnet_helm_chart_version" {
  type = string 
  default = "0.1.0"
}

# variable "seed_peers" {
#   type    = list
# }

variable "coda_privkey_pass" {
  type    = string
}

variable "starting_host_ports" {
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