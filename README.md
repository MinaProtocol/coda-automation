![Coda Logo](https://cdn.codaprotocol.com/v4/static/img/coda-logo.png)

# Repository Purpose 
This repository is designed to show an opinionated example on how to operate a network of Coda Daemons. It implements the entire node lifecycle using a modern Infrastructure as Code toolset. Community contributions are warmly encouraged, please see the [contribution guidelines](#to-do) for more details. The code is designed to be as modular as possible, allowing the end-user to "pick and choose" the parts they would like to incorporate into their own infrastructure stack. 

If you have any issues setting up your testnet or have any other questions about this repository, join the public [Discord Server](https://discord.gg/ShKhA7J) and get help from the Coda community.

# Code Structure
```
coda-automation
├── helm
│   ├── block-producer
│   └── snark-worker
├── scripts
├── services
└── terraform
    ├── infrastructure
    ├── modules
    └── testnets
```

**Terraform:** Contains resource modules and live code to deploy a Coda Testnet. 
- Note: Currently most modules are written against Google Kubernetes Engine, multi-cloud support is on the roadmap.
- *infrastructure:* The root module for infrastructure like K8s Clusters and Prometheus.
- *kubernetes/testnet:* A Terraform module that encapsulates a Coda Testnet, including Seed Nodes, Block Producers and SNARK Workers.
- *google-cloud/coda-seed-node:* A Terraform module that deploys a set of public Seed Nodes on Google Compute Engine in the configured region. 
*Scripts:* Testnet utilities for key generation & storage, redelegation, etc. 

# Prerequisites
For the purposes of this README we are assuming the following: 
- You have a configured AWS Account with credentials on your machine
- You have Terraform `0.12.x` installed on your machine
- You have Ansible `2.8.x` installed on your machine

# Key Terms
- *Netname*: The common name used to refer to a particular instance of a Test Network. (ex: "20190601") 

# Getting Started 
There's several steps involved in setting up Coda nodes, and the setup process can vary slightly depending on your end-goal: 
1. I'd like to set up a Coda Test Network from scratch. 
2. I'd like to join my Coda Nodes to an existing Test Network. 



## Start Your Own Test Network From Scratch

### Clone the Repository
`git clone https://github.com/CodaProtocol/coda-automation.git`

### Create a new Testnet Terraform configuration
Note: You can totally use one of the existing example configurations, but we'll assume you want to set one up from the beginning.
``` bash
$ cd coda-automation/terraform/testnets
$ mkdir testnet$(date +"%Y%m%d")
$ touch testnet$(date +"%Y%m%d")/testnet.tf
```

### Populate it with your node configuration and (optionally) other infrastructure
**Bare-Minimum testnet.tf:**
```
locals {
  netname    = "20190601"                                                                                                                                                                                                                                                                                                                                                               
  public_key = "< INSERT SSH KEY HERE> "
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

## One Seed
module "us-west-2-seed" {
  source        = "../../modules/coda-node"
  region        = "us-west-2"
  server_count  = 1
  instance_type = "c5.xlarge"
  netname       = "${local.netname}"
  rolename      = "seed"
  public_key    = "${local.public_key}"
}

## One Snarker
module "us-west-2-snarker" {
  source        = "../../modules/coda-node"
  region        = "us-west-2"
  server_count  = 1
  instance_type = "c5.4xlarge"
  netname       = "${local.netname}"
  rolename      = "snarker"
  public_key    = "${local.public_key}"
}

# Three Proposers
module "us-west-2-proposer" {
  source        = "../../modules/coda-node"
  region        = "us-west-2"
  server_count  = 3
  instance_type = "c5.2xlarge"
  netname       = "${local.netname}"
  rolename      = "proposer"
  public_key    = "${local.public_key}"
}
```

If you were to `terraform apply` this, you would get 5 instances, all in AWS's `us-west-2` region. However there are no Coda daemons installed! 

### Run Ansible against your Coda Testnet
Next, we need to install the Coda daemon.
- Note: currently, the `coda-init.yaml` runbook installs elastic beats for log collection, more flexible runbooks are on the roadmap. 
- Note: currently the `coda-init.yaml` runbook installs SSH Keys for the core Coda team to debug nodes. You should modify `ansible/tasks/task-sshkeys.yaml` to reflect your github username before executing this runbook.
- Note: see `ansible/tasks` for a detailed list of installation steps.  
```
$ cd coda-automation/ansible
$ ansible-playbook -i ec2.py -u admin -e netname=$(date +"%Y%m%d") coda-init.yaml
```

The `coda-init.yaml` runbook will SSH to all the machines in your testnet, performing required configuration actions in order to get the nodes in a runnable state. 

The actions it performs are the following: 
- Install Elastic Beats for log forwarding/metrics
- Download and Install Proving Keys (see note below)
- Install Coda + Dependencies
- Install SSH Public Keys for management

**Note about Proving Keys:** Proving keys are generated at Daemon build time and must be fetched before running the Coda Daemon. There is currently no established location to download these keys, however once one is introduced this README will be updated with instructions on how to retrieve them. 

Lastly, you must run the `coda-start.yaml` runbook to start the Daemons in the correct order. 

```
$ ansible-playbook -i ec2.py -u admin -e netname=$(date +"%Y%m%d") coda-start.yaml
```

This step will start the seed node, then join any Snarkers to the network before joining any Proposers. 

## Join Your Coda Nodes to an Existing Test Network

**TO DO**

# Next Steps
Now that you have a testnet running, there's plenty of things you can do: 
- Let us know! Join the public [Discord Server](https://discord.gg/ShKhA7J). 
- Fund your wallets -- Sign up for the [testnet faucet](#to-do)!
- Monitor your nodes with our [Kibana Dashboards](#to-do).
- Script interactions with the network via the [Python Library](#to-do). 
- Contribute to this or one of our other [Open Source Projects](#to-do)! 