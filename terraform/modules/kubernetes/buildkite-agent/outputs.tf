output "cluster_details" {
  value = helm_release.buildkite_agents.metadata
}
