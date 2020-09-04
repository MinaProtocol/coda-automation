locals {
  prometheus_helm_values = {
    server = {
      global = {
        external_labels = {
          origin_prometheus = "buildkite-${var.cluster_name}-prometheus"
        }
      }
      persistentVolume = {
        size = "25Gi"
      }
      remoteWrite = [
        {
          url = jsondecode(data.aws_secretsmanager_secret_version.current_prometheus_remote_write_config.secret_string)["remote_write_uri"]
          basic_auth = {
            username = jsondecode(data.aws_secretsmanager_secret_version.current_prometheus_remote_write_config.secret_string)["remote_write_username"]
            password = jsondecode(data.aws_secretsmanager_secret_version.current_prometheus_remote_write_config.secret_string)["remote_write_password"]
          }
          write_relabel_configs = [
            {
              source_labels: ["__name__"]
              regex: "(container.*)"
              action: "keep"
            }
          ]
        }
      ]
    }
  }
}

resource "helm_release" "buildkite_prometheus" {
  name      = "buildkite-${var.cluster_name}-prometheus"
  chart     = "stable/prometheus"
  namespace = var.cluster_name

  values = [
    yamlencode(local.prometheus_helm_values)
  ]
  wait       = true
  force_update  = true
  depends_on = [helm_release.buildkite_agents]
}