locals {
    production_filter = "testnet=~\"testworld|mainnet|qanet\""
}
locals {
  testnet_alerts = {
    groups = [
        {
            name = "Critical Alerts"
            rules = [
                {
                    alert   = "BlockProductionStopped"
                    expr    = "avg by (testnet) (increase(Coda_Transition_frontier_max_blocklength_observed{${local.production_filter}}[5m])) < 1"
                    for   = "1h"
                    labels = {
                        severity = "critical"
                    }
                    annotations = {
                        description = "Zero blocks have been produced on testnet {{ $labels.testnet }} for more than 1 hour."
                        summary     = "{{ $labels.testnet }} block production is critically low"
                    }
                },
                {
                    alert   = "LowPeerCount"
                    expr    = "avg by (testnet) (max_over_time(Coda_Network_peers{${local.production_filter}}[1h])) < 1"
                    for   = "1h"
                    labels = {
                        severity = "critical"
                    }
                    annotations = {
                        description = "Critically low peer count on testnet {{ $labels.testnet }} for more than 1 hour."
                        summary     = "{{ $labels.testnet }} avg. peer count is critically low"
                    }
                }
            ]
        }
    ]
  }
  pagerduty_receivers = [
    {
        name = "pagerduty-testnet-primary"
        pagerduty_configs = [
            {
                service_key = "${data.aws_secretsmanager_secret_version.pagerduty_testnet_primary_key_id.secret_string}"
            }
        ]
    }
  ]
}
