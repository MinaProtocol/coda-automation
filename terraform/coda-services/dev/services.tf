data "aws_secretsmanager_secret" "discord_api_key" {
  name = "coda-services/faucet/discord_api_key/staging"
}

data "aws_secretsmanager_secret_version" "current_discord_api_key" {
  secret_id = "${data.aws_secretsmanager_secret.discord_api_key.id}"
}

# data "aws_secretsmanager_secret" "daemon_aws_access_keys" {
#   name = "coda-services/daemon/daemon_aws_access_keys"
# }

# data "aws_secretsmanager_secret_version" "current_daemon_aws_access_keys" {
#   secret_id = "${data.aws_secretsmanager_secret.daemon_aws_access_keys.id}"
# }

# data "aws_secretsmanager_secret" "service_daemon_privkey_pass" {
#   name = "coda-services/daemon/service_daemon_privkey_pass"
# }

# data "aws_secretsmanager_secret_version" "current_service_daemon_privkey_pass" {
#   secret_id = "${data.aws_secretsmanager_secret.service_daemon_privkey_pass.id}"
# }

# ## Faucet
# module "faucet" {
#     #source = "github.com/codaprotocol/coda-automation/terraform/modules/services/prometheus"
#     source = "../../modules/services/faucet"

#     # Global Vars
#     ecs_cluster_id = "O1Labs-Services"
#     environment = "dev"
#     testnet = "TEST"

#     # Faucet Variables
#     faucet_container_version = "0.0.9-statuslog"
#     faucet_public_key = "tdNE67M9Snd4KF2Y3xgCQ8Res8LQxckx5xpraAAfa9uv1P6GUy8a6QkXbLnN8PknuKDknEerRCYGujScean4D88v5sJcTqiuqnr2666Csc8QhpUW6MeXq7MgEha7S6ttxB3bY9MMVrDNBB"
#     echo_public_key = "tdNDk6tKpzhVXUqozR5y2r77pppsEak7icvdYNsv2dbKx6r69AGUUbQsfrHHquZipQCmMj4VRhVF3u4F5NDgdbuxxWANULyVjUYPbe85fv7bpjKRgSpGR3zo2566s5GNNKQyLRUm12wt5o"
#     coda_graphql_host = "localhost"
#     discord_api_key = jsondecode(data.aws_secretsmanager_secret_version.current_discord_api_key.secret_string)["discord_api_key"]
#     faucet_password = ""
#     echo_password = ""
#     fee_amount = 10

#     # Daemon Variables
#     coda_container_version = "0.0.9"
#     coda_wallet_keys = "testnet/keys/echo/0 testnet/keys/grumpus/0"
#     aws_access_key = jsondecode(data.aws_secretsmanager_secret_version.current_daemon_aws_access_keys.secret_string)["AWS_ACCESS_KEY_ID"]
#     aws_secret_key = jsondecode(data.aws_secretsmanager_secret_version.current_daemon_aws_access_keys.secret_string)["AWS_SECRET_ACCESS_KEY"]
#     aws_default_region = "us-west-2"
#     coda_peer = "seared-kobe.o1test.net:8303"
#     coda_rest_port = 8304
#     coda_external_port = 10101
#     coda_metrics_port = 10000
#     coda_privkey_pass = "testnet"
# }
