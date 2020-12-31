locals {
  production_filter = "testnet=~\"testworld|mainnet|qanet\""
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
                        description = "Zero blocks have been produced on testnet {{ $labels.testnet }}."
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
                        description = "Critically low peer count on testnet {{ $labels.testnet }}."
                        summary     = "{{ $labels.testnet }} avg. peer count is critically low"
                    }
                }
            ]
        },
        {
            name = "Warnings"
            rules = [
                {
                    alert   = "HighBlockGossipLatency"
                    expr    = "avg by (testnet) (max_over_time(Coda_Block_latency_gossip_time{${local.production_filter}}[1h])) > 200"
                    for   = "1h"
                    labels = {
                        severity = "warning"
                    }
                    annotations = {
                        description = "High block gossip latency (ms) within {{ $labels.testnet }} testnet."
                        summary     = "{{ $labels.testnet }} block gossip latency is high"
                    }
                },
                {
                    alert   = "ZeroSnarkFeesObserved"
                    expr    = "max by (testnet) (Coda_Snark_work_snark_fee_bucket{${local.production_filter}} == 0)"
                    for   = "1h"
                    labels = {
                        severity = "warning"
                    }
                    annotations = {
                        description = "Transactions containing zero SNARK fees observed on testnet {{ $labels.testnet }} for more than 1 hour."
                        summary     = "{{ $labels.testnet }} SNARK work fees of zero Mina observed."
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
