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
      "secretsmanager:TagResource"
    ]

    effect = "Allow"

    # TODO: narrow to buildkite agent pipeline specific set of secrets
    resources = [
      "*",
    ]
  }
  statement {
    actions = [
      "s3:GetObject*",
      "s3:PutObject*",
      "s3:ListObjects*",
      "s3:HeadObject*",
      "s3:CopyObject*",
      "s3:DeleteObject*",
      "s3:MultipartUpload*"
    ]

    effect = "Allow"

    resources = [
      "arn:aws:s3:::packages.o1test.net",
      "arn:aws:s3:::*.o1test.net"
    ]
  }
}

resource "aws_iam_user_policy" "buildkite_aws_policy" {
  name = "buildkite_agent_policy"
  user = aws_iam_user.buildkite_aws_user.name

  policy = data.aws_iam_policy_document.buildkite_aws_policydoc.json
}

data "aws_secretsmanager_secret" "buildkite_docker_token_metadata" {
  name = "o1bot/docker/ci-access-token"
}

data "aws_secretsmanager_secret_version" "buildkite_docker_token" {
  secret_id = "${data.aws_secretsmanager_secret.buildkite_docker_token_metadata.id}"
}
