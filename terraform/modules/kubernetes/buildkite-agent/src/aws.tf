# activated for AWS secrets manager interfacing
provider "aws" {
  region = "us-west-2"
}

data "aws_iam_policy_document" "buildkite_aws_policy" {
  statement {
    actions = [
      "secretsmanager:GetSecretValue",
    ]

    # TODO: narrow to buildkite agent pipeline specific set of secrets
    resources = [
      "*",
    ]
  }
}

resource "aws_iam_role" "buildkite_agent" {
  name = "buildkite_agent"

  force_detach_policies = true

  assume_role_policy = "${data.aws_iam_policy_document.buildkite_aws_policy.json}"

  tags = {
    cluster = var.cluster_name
  }
}
