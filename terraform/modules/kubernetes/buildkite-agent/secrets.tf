resource "kubernetes_secret" "google_application_credentials" {
  metadata {
    name      = "google-application-credentials"
    namespace = kubernetes_namespace.cluster_namespace.metadata[0].name
    annotations = {
      "kubernetes.io/service-account.name" = "google-application-credentials"
    }
  }

  data = {
    "credentials_json" = "value"
  }
}

resource "kubernetes_secret" "buildkite_agent_token" {
  metadata {
    name      = "buildkite-agent-token"
    namespace = kubernetes_namespace.cluster_namespace.metadata[0].name
  }

  data = {
    "agent_token" = var.agent_token
  }
}