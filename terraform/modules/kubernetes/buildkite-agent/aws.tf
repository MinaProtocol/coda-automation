# activated for AWS secrets manager interfacing
provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_user" "buildkite_aws_user" {
  name = "buildkite-${var.cluster_name}"
  path = "/service-accounts/"
}

resource "aws_iam_access_key" "buildkite_aws_key" {
  user    = aws_iam_user.buildkite_aws_user.name
}

data "aws_iam_policy_document" "buildkite_aws_policydoc" {
  statement {
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:ListSecrets",
      "secretsmanager:TagResouce"
    ]

    effect = "Allow"

    # TODO: narrow to buildkite agent pipeline specific set of secrets
    resources = [
      "*",
    ]
  }
}

resource "aws_iam_user_policy" "buildkite_aws_policy" {
  name = "buildkite_agent_policy"
  user = aws_iam_user.buildkite_aws_user.name

  policy = data.aws_iam_policy_document.buildkite_aws_policydoc.json
}
