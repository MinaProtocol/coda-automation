![Coda Logo](https://github.com/CodaProtocol/coda/blob/develop/frontend/website/public/static/img/coda-logo%403x.png)
<a href="https://codaprotocol.com">
	<img width="200" src="https://github.com/CodaProtocol/coda/blob/develop/frontend/website/public/static/img/coda-logo@3x.png" alt="Coda Logo" />
</a>
<hr/>

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

**Helm:** Contains Helm Charts for various components of a Coda Testnet
- *block-producer:* One or more block producers consisting of unique `deployments`
- *snark-worker:*  Deploys a "SNARK Coordinator" consisting of one or more worker process containers

**Terraform:** Contains resource modules and live code to deploy a Coda Testnet. 
- Note: Currently most modules are written against Google Kubernetes Engine, multi-cloud support is on the roadmap.
- *infrastructure:* The root module for infrastructure like K8s Clusters and Prometheus.
- *kubernetes/testnet:* A Terraform module that encapsulates a Coda Testnet, including Seed Nodes, Block Producers and SNARK Workers.
- *google-cloud/coda-seed-node:* A Terraform module that deploys a set of public Seed Nodes on Google Compute Engine in the configured region. 
*Scripts:* Testnet utilities for key generation & storage, redelegation, etc. 

# Prerequisites
For the purposes of this README we are assuming the following: 
- You have a configured AWS Account with credentials on your machine
- You have a configured Google Cloud Project with credentials on your machine
- You have Terraform `0.12.x` installed on your machine

# Deploy a Testnet

### Clone the Repository

### Apply the Infrastructure Module

### Create and Apply a Testnet Module

### Upload Keys

# Next Steps
Now that you have a testnet running, there's plenty of things you can do: 
- Let us know! Join the public [Discord Server](https://discord.gg/ShKhA7J). 
- Fund your wallets -- Sign up for the [testnet faucet](#to-do)!
- Monitor your nodes with our [Kibana Dashboards](#to-do).
- Script interactions with the network via the [Python Library](#to-do). 
- Contribute to this or one of our other [Open Source Projects](#to-do)! 
