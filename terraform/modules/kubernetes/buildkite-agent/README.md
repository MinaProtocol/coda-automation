<p><img src="https://www.thepracticalsysadmin.com/wp-content/uploads/2020/03/terraform1.png" alt="Terraform logo" title="terraform" align="left" height="60" /></p>
<p><img src="https://buildkite.com/docs/assets/integrations/github_enterprise/buildkite-square-58030b96d33965fef1e4ea8c6d954f6422a2489e25b6b670b521421fcaa92088.png" alt="buildkite logo" title="buildkite" align="right" height="100" /></p>

# Buildkite Agent Terraform Module (K8s/GKE)

## Providers

| Name | Version |
|------|---------|
| google | n/a |
| helm | n/a |
| kubernetes | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:-----:|
| cluster\_name | Name of K8s Buildkite Agent cluster to provision | `string` | n/a | yes |
| agent\_token | Agent registration token for connection with Buildkite server | `string` | n/a | yes |
| agent\_vcs\_privkey | Agent SSH private key for access to (Github) version control system | `string` | n/a | no |
| agent\_meta | Agent metadata or labels used to managed job scheduling (comma-separated list) | `string` | `role=agent` | no |
| agent\_version | Version of Buildkite agent to launch | `string` | 3 | no |
| num\_agents | Number of agents to provision within cluster | `number` | `1` | no |
| agent\_config | `Buildkite agent configuration options (see: https://github.com/buildkite/charts/blob/master/stable/agent/README.md#configuration)` | `map(string)` | `{}` | no |
| helm\_repo | Repository URL where to locate the requested chart Buildkite chart. | `string` | `https://buildkite.github.io/charts/` | no |
| chart\_version | Buildkite chart version to provision | `string` | `0.3.14` | no |
| cluster\_namespace | K8s namespace to install the cluster release into | `string` | `default` | no |
| image\_pullPolicy | Agent container image pull policy | `string` | `IfNotPresent` | no |
| dind\_enabled | Whether to enable a preset Docker-in-Docker(DinD) pod configuration | `bool` | `false` | no |
| k8s\_cluster\_name | Infrastructure Kubernetes cluster to provision to Buildkite agents on | `string` | `coda-infra-east` | no |
| k8s\_cluster\_region | Kubernetes cluster region | `string` | `useast-1` | no |

## Outputs

| Name | Description |
|------|-------------|
| k8s cluster details | Cluster specification and status information following provisioning |

