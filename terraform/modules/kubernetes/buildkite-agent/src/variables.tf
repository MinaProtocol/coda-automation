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
  type = string

  description = "Agent registration token for connection with Buildkite server"
}

variable "agent_vcs_privkey" {
  type = string

  description = "Agent SSH private key for access to (Github) version control system"
  default     = ""
}

variable "agent_version" {
  type = string

  description = "Version of Buildkite agent to launch"
  default     = "3"
}

variable "agent_config" {
  type = map(string)

  description = "Buildkite agent configuration options (see: https://github.com/buildkite/charts/blob/master/stable/agent/README.md#configuration)"
  default     = {}
}

variable "agent_topology" {
  description = "Buildkite agent compute resource topology - <agent role => system resource requests> (see: https://github.com/buildkite/charts/blob/master/stable/agent/values.yaml#L74)"
  default     = {}
}

variable "artifact_upload_bin" {
  type = string

  description = "Path to agent artifact upload binary"
  default     = "/usr/local/google-cloud-sdk/bin/gsutil"
}

variable "artifact_upload_path" {
  type = string

  description = "Path to upload agent job artifacts"
  default     = "gs://buildkite_k8s/coda/shared"
}

# Module Vars: Helm Chart
variable "helm_chart" {
  type = string

  description = "Identifier of Buildkite helm chart."
  default     = "buildkite/agent"
}

variable "helm_repo" {
  type = string

  description = "Repository URL where to locate the requested chart Buildkite chart."
  default     = "https://buildkite.github.io/charts/"
}

variable "chart_version" {
  type = string

  description = "Buildkite chart version to provision"
  default     = "0.3.16"
}

variable "k8s_provider" {
  type = string

  description = "K8s resource provider"
  default     = "minikube"
}

variable "image_pullPolicy" {
  type = string

  description = "Agent container image pull policy"
  default     = "IfNotPresent"
}

variable "dind_enabled" {
  type = bool

  description = "Whether to enable a preset Docker-in-Docker(DinD) pod configuration"
  default     = true
}
