provider helm {}

# Helm Buildkite Agent Spec
locals {
  buildkite_config_envs = [
    # inject Google Cloud application credentials into agent runtime for enabling buildkite artifact uploads
    {
      "name" = "BUILDKITE_GS_APPLICATION_CREDENTIALS_JSON"
      "value" = var.k8s_provider != local.gke_context ? var.google_app_credentials : base64decode(google_service_account_key.buildkite_svc_key[0].private_key)
    },
    # used by GSUTIL tool for accessing GCS data
    {
      "name" = "CLUSTER_SERVICE_EMAIL"
      "value" = var.k8s_provider == local.gke_context ? google_service_account.gcp_buildkite_account[0].email : ""
    },
    {
      "name" = "BUILDKITE_ARTIFACT_UPLOAD_DESTINATION"
      "value" = var.artifact_upload_path
    },
    {
      "name" = "UPLOAD_BIN"
      "value" = var.artifact_upload_bin
    },
    {
      "name" = "GSUTIL_DOWNLOAD_URL"
      "value" = var.gsutil_download_url
    },
    {
      "name" = "SUMMON_DOWNLOAD_URL"
      "value" = var.summon_download_url
    },
    {
      "name" = "SECRETSMANAGER_DOWNLOAD_URL"
      "value" = var.secretsmanager_download_url
    }
  ]
}

locals {
  default_agent_vars = {
    image = {
      tag        = var.agent_version
      pullPolicy = var.image_pullPolicy
    }

    agent = {
      token = var.agent_token
      meta  = "role=coda-agent"
    }
    privateSshKey = var.agent_vcs_privkey

    # Using Buildkite's config-setting <=> env-var mapping, convert all k,v's stored within agent config as extra environment variables
    # in order to specify custom configuration (see: https://buildkite.com/docs/agent/v3/configuration#configuration-settings)
    extraEnv = concat(local.buildkite_config_envs,
    [for key, value in var.agent_config : { "name" : "BUILDKITE_$(upper(key))", "value" : value }])

    dind = {
      enabled = var.dind_enabled
    }

    entrypointd = {
      "01-install-gsutil" = <<EOF
        #!/bin/bash

        set -eou pipefail
        set +x

        if [[ ! -f $UPLOAD_BIN ]]; then
          echo "Downloading gsutil because it doesn't exist"
          wget $GSUTIL_DOWNLOAD_URL

          tar -zxf $(basename ${GSUTIL_DOWNLOAD_URL}) -C /usr/local/

          echo "$BUILDKITE_GS_APPLICATION_CREDENTIALS_JSON" > /tmp/gcp_creds.json

          export GOOGLE_APPLICATION_CREDENTIALS=/tmp/gcp_creds.json && /usr/local/google-cloud-sdk/bin/gcloud auth activate-service-account ${CLUSTER_SERVICE_EMAIL} --key-file /tmp/gcp_creds.json
        fi
      EOF

      "01-install-summon" = <<EOF
        #!/bin/bash

        set -eou pipefail
        set +x

        export SUMMON_BIN=/usr/local/bin/summon
        export SECRETSMANAGER_LIB=/usr/local/lib/summon-aws-secrets

        # download and install summon binary executable
        if [[ ! -f ${SUMMON_BIN} ]]; then
          echo "Downloading summon because it doesn't exist"
          wget ${SUMMON_DOWNLOAD_URL}

          tar -xzf $(basename ${SUMMON_DOWNLOAD_URL}) -C /usr/local/bin/
        fi

        # download and install summon AWS Secrets provider
        if [[ ! -f ${SECRETSMANAGER_LIB} ]]; then
          echo "Downloading summon AWS secrets manager because it doesn't exist"
          wget ${SECRETSMANAGER_DOWNLOAD_URL}

          tar -xzf $(basename ${SECRETSMANAGER_DOWNLOAD_URL}) -C /usr/local/lib/
        fi
      EOF
    }
  }
}

data "helm_repository" "buildkite_helm_repo" {
  name = "buildkite"
  url  = "https://buildkite.github.io/charts/"
}

resource "helm_release" "buildkite_agents" {
  for_each   = var.agent_topology
 
  name       = "${var.cluster_name}-buildkite-${each.key}"
  repository = data.helm_repository.buildkite_helm_repo.metadata[0].name
  chart      = var.helm_chart
  namespace  = kubernetes_namespace.cluster_namespace.metadata[0].name

  values = [
    yamlencode(merge(local.default_agent_vars, each.value))
  ]

  wait = false
}
