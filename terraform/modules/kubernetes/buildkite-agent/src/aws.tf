# activated for AWS secrets manager interfacing
provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "buildkite_agent" {
  name = "buildkite_agent"

  force_detach_policies = true

  assume_role_policy = <<EOF
{
"Version" : "2020-06-24",
  "Statement" : [
    {
      "Effect": "Allow",
      "Principal": {<insert-proper-principla>},
      "Action": "secretsmanager:GetSecretValue",
      "Resource": "*",
      "Condition": {
        "ForAnyValue:StringEquals": {
          "secretsmanager:VersionStage" : "AWSCURRENT"
        }
      }
    }
  ]
}
EOF

  tags = {
    cluster = var.cluster_name
  }
}