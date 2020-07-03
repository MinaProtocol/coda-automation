# K8s Cluster Vars

variable "google_app_credentials" {
  type = string

  description = "Google application credentials for enabling upload/download to GCS"
  default     = ""
}

variable "cloud_env" {
  type = bool

  description = "Whether operating in a kubernetes cloud environment"
  default = true
}

variable "k8s_context" {
  type = string

  description = "K8s resource provider context"
  default     = "minikube"
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
  default     = "3-ubuntu"
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

variable "gsutil_download_url" {
  type = string

  description = "gsutil tool archive download URL"
  default = "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-296.0.1-linux-x86_64.tar.gz"
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

# Module Vars: Summon secrets management
variable "summon_download_url" {
  type = string

  description = "Summon secrets management binary download URL"
  default = "https://github.com/cyberark/summon/releases/download/v0.8.1/summon-linux-amd64.tar.gz"
}

variable "secretsmanager_download_url" {
  type = string

  description = "AWS secrets manager summon provider download URL"
  default = "https://github.com/cyberark/summon-aws-secrets/releases/download/v0.3.0/summon-aws-secrets-linux-amd64.tar.gz"
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
