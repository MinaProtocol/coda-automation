# K8s Cluster Vars

variable "google_app_credentials" {
  type = string

  description = "Google application credentials for enabling upload/download to GCS"
  default     = ""
}

variable "k8s_cluster_name" {
  type = string

  description = "Kubernetes cluster to provision to Buildkite agents on"
  default     = "coda-infra-east"
}

variable "k8s_cluster_region" {
  type = string

  description = "Kubernetes cluster region"
  default     = "us-east1"
}

# Module Vars: Agent

variable "cluster_name" {
  type = string

  description = "Name of K8s Buildkite Agent cluster to provision"
}

variable "agent_token" {
  type    = string

  description = "Agent registration token for connection with Buildkite server"
}

variable "agent_vcs_privkey" {
  type    = string

  description = "Agent SSH private key for access to (Github) version control system"
}

variable "agent_meta" {
  type    = string

  description = "Agent metadata or labels used to managed job scheduling"
  default = "role=agent"
}

variable "agent_version" {
  type    = string

  description = "Version of Buildkite agent to launch"
  default = "3"
}

variable "num_agents" {
  type    = number

  description = "Number of Buildkite agents to provision"
  default = 1
}

variable "agent_config" {
  type        = map(string)

  description = "Buildkite agent configuration options (see: https://github.com/buildkite/charts/blob/master/stable/agent/README.md#configuration)"
  default     = {}
}

variable "agent_resources" {
  type        = map(string)

  description = "Buildkite agent compute resource request and limits (see: https://github.com/buildkite/charts/blob/master/stable/agent/values.yaml#L74)"
  default     = {}
}

# Module Vars: Helm Chart
variable "helm_chart" {
  type    = string

  description = "Identifier of Buildkite helm chart."
  default = "buildkite/agent"
}

variable "helm_repo" {
  type    = string

  description = "Repository URL where to locate the requested chart Buildkite chart."
  default = "https://buildkite.github.io/charts/"
}

variable "chart_version" {
  type    = string

  description = "Buildkite chart version to provision"
  default = "0.3.14"
}

variable "cluster_namespace" {
  type = string

  description = "K8s namespace to install the cluster release into"
  default = "default"
}

variable "k8s_provider" {
  type = string

  description = "K8s resource provider"
  default = "minikube"
}

variable "image_pullPolicy" {
  type    = string

  description = "Agent container image pull policy"
  default = "IfNotPresent"
}

variable "dind_enabled" {
  type    = bool

  description = "Whether to enable a preset Docker-in-Docker(DinD) pod configuration"
  default = true
}
