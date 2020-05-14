provider helm {
  kubernetes {
    config_context         = var.k8s_provider
    config_context_cluster = var.k8s_provider
  }
}

# Helm Buildkite Agent Spec
locals {
  # set Google Cloud application credentials created for this cluster to inject into agent runtime
  google_access_config = [
    {
      "name" : "BUILDKITE_GS_APPLICATION_CREDENTIALS_JSON",
      "value" : var.k8s_provider == local.gke_context ? google_service_account_key.buildkite_svc_key[0].private_key : var.google_app_credentials
    }
  ]
}
locals {
  buildkite_agent_vars = {
    replicaCount = var.num_agents
    image = {
      tag        = var.agent_version
      pullPolicy = var.image_pullPolicy
    }

    agent = {
      token = var.agent_token
      meta  = var.agent_meta
    }
    privateSshKey = var.agent_vcs_privkey

    resources = var.agent_resources
    # Using Buildkite's config-setting <=> env-var mapping, convert all k,v's stored within agent config as extra environment variables
    # in order to specify custom configuration (see: https://buildkite.com/docs/agent/v3/configuration#configuration-settings)
    extraEnv = concat(local.google_access_config,
    [for key, value in var.agent_config : { "name" : "BUILDKITE_$(upper(key))", "value" : value }])

    dind = {
      enabled = var.dind_enabled
    }
  }
}

data "helm_repository" "buildkite_helm_repo" {
  name = "buildkite"
  url  = "https://buildkite.github.io/charts/"
}

resource "helm_release" "buildkite_agents" {
  name       = "${var.cluster_name}-buildkite"
  repository = data.helm_repository.buildkite_helm_repo.metadata[0].name
  chart      = var.helm_chart
  namespace  = kubernetes_namespace.cluster_namespace.metadata[0].name

  values = [
    yamlencode(local.buildkite_agent_vars)
  ]

  wait = false
}
