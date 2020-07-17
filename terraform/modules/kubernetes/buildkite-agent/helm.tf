provider kubernetes {
    config_context  = var.k8s_context
}

provider helm {
  kubernetes {
    config_context  = var.k8s_context
  }
}

resource "kubernetes_namespace" "cluster_namespace" {
  metadata {
    name = var.cluster_name
  }
}

# Helm Buildkite Agent Spec
locals {
  buildkite_config_envs = [
    # Buildkite EnvVars
    {
      # inject Google Cloud application credentials into agent runtime for enabling buildkite artifact uploads
      "name" = "BUILDKITE_GS_APPLICATION_CREDENTIALS_JSON"
      "value" = var.enable_gcs_access ? base64decode(google_service_account_key.buildkite_svc_key[0].private_key) : var.google_app_credentials
    },
    {
      "name" = "BUILDKITE_ARTIFACT_UPLOAD_DESTINATION"
      "value" = var.artifact_upload_path
    },
    # Summon EnvVars
    {
      "name" = "SUMMON_DOWNLOAD_URL"
      "value" = var.summon_download_url
    },
    {
      "name" = "SECRETSMANAGER_DOWNLOAD_URL"
      "value" = var.secretsmanager_download_url
    },
    # Google Cloud EnvVars
    {
      # used by GSUTIL tool for accessing GCS data
      "name" = "CLUSTER_SERVICE_EMAIL"
      "value" = var.enable_gcs_access? google_service_account.gcp_buildkite_account[0].email : ""
    },
    {
      "name" = "GSUTIL_DOWNLOAD_URL"
      "value" = var.gsutil_download_url
    },
    {
      "name" = "UPLOAD_BIN"
      "value" = var.artifact_upload_bin
    },
    # AWS EnvVars
    {
      "name" = "AWS_ACCESS_KEY_ID"
      "value" = aws_iam_access_key.buildkite_aws_key.id
    },
    {
      "name" = "AWS_SECRET_ACCESS_KEY"
      "value" = aws_iam_access_key.buildkite_aws_key.secret
    },
    {
      "name" = "AWS_REGION"
      "value" = "us-west-2"
    },
    # Docker EnvVars
    {
      "name" = "DOCKER_PASSWORD"
      "value" = data.aws_secretsmanager_secret_version.buildkite_docker_token.secret_string
    }
  ]
}

locals {
  default_agent_vars = {
    image = {
      tag        = var.agent_version
      pullPolicy = var.image_pullPolicy
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
      "01-install-gsutil" = <<-EOF
        #!/bin/bash

        set -eou pipefail
        set +x

        if [[ ! -f $${UPLOAD_BIN} ]]; then
          echo "Downloading gsutil because it doesn't exist"
          apt-get -y update && apt install -y wget python && wget $${GSUTIL_DOWNLOAD_URL}

          tar -zxf $(basename $${GSUTIL_DOWNLOAD_URL}) -C /usr/local/

          echo "$${BUILDKITE_GS_APPLICATION_CREDENTIALS_JSON}" > /tmp/gcp_creds.json

          export GOOGLE_APPLICATION_CREDENTIALS=/tmp/gcp_creds.json && /usr/local/google-cloud-sdk/bin/gcloud auth activate-service-account $${CLUSTER_SERVICE_EMAIL} --key-file /tmp/gcp_creds.json
        fi
      EOF

      "01-install-summon" = <<-EOF
        #!/bin/bash

        set -eou pipefail
        set +x

        export SUMMON_BIN=/usr/local/bin/summon
        export SECRETSMANAGER_LIB=/usr/local/lib/summon/summon-aws-secrets

        # download and install summon binary executable
        if [[ ! -f $${SUMMON_BIN} ]]; then
          echo "Downloading summon because it doesn't exist"
          apt-get -y update && apt install -y wget && wget $${SUMMON_DOWNLOAD_URL}

          tar -xzf $(basename $${SUMMON_DOWNLOAD_URL}) -C /usr/local/bin/
        fi

        # download and install summon AWS Secrets provider
        if [[ ! -f $${SECRETSMANAGER_LIB} ]]; then
          echo "Downloading summon AWS secrets manager because it doesn't exist"
          wget $${SECRETSMANAGER_DOWNLOAD_URL}

          mkdir -p $(dirname $${SECRETSMANAGER_LIB})
          tar -xzf $(basename $${SECRETSMANAGER_DOWNLOAD_URL}) -C $(dirname $${SECRETSMANAGER_LIB})
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
 
  name              = "${var.cluster_name}-buildkite-${each.key}"
  repository        = data.helm_repository.buildkite_helm_repo.metadata[0].name
  chart             = var.helm_chart
  namespace         = var.cluster_name
  create_namespace  = true

  values = [
    yamlencode(merge(local.default_agent_vars, each.value))
  ]

  wait = false
}
