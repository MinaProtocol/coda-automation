provider helm {
  kubernetes {
    host                   = "https://${data.google_container_cluster.cluster.endpoint}"
    client_certificate     = base64decode(data.google_container_cluster.cluster.master_auth[0].client_certificate)
    client_key             = base64decode(data.google_container_cluster.cluster.master_auth[0].client_key)
    cluster_ca_certificate = base64decode(data.google_container_cluster.cluster.master_auth[0].cluster_ca_certificate)
    token                  = data.google_client_config.current.access_token
    load_config_file       = false
  }
}

data "helm_repository" "buildkite_helm_repo" {
  name = "buildkite-helm-repo"
  url  = var.helm_repo
}

# Helm Buildkite Agent Spec
locals {
  buildkite_agent_vars = {
    numAgents                 =   var.num_agents
    image = {
      tag                     =   var.agent_version
      pullPolicy              =   var.image_pullPolicy
    }

    agentToken                =   var.agent_token
    privateSshKey             =   var.agent_vcs_privkey
    agentMeta                 =   var.agent_meta

    # Using Buildkite's config-setting <=> env-var mapping, convert all k,v's stored within agent config as extra environment variables
    # in order to specify custom configuration (see: https://buildkite.com/docs/agent/v3/configuration#configuration-settings)
    extraEnv                  =   [for key, value in var.agent_config : {"name": "BUILDKITE_${upper(replace(name, '-', '_'))}", "value": value}]
    
    dind = {
      enabled                 =   var.dind_enabled
    }
  }
}

resource "helm_release" "buildkite_agents" {
  name       = "${var.cluster_name}-buildkite"
  repository = "${data.helm_repository.buildkite_helm_repo}"
  chart      = "${var.helm_chart}"
  namespace  = kubernetes_namespace.cluster_namespace.metadata[0].name
  values     = [
    yamlencode(local.buildkite_agent_vars)
  ]
  wait       = false
}
