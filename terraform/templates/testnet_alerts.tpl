groups:
- name: Critical Alerts
  rules:
  - alert: BlockProductionStopped
    annotations:
      description: "Zero blocks have been produced on testnet {{ $labels.testnet }}."
      summary: {{ $labels.testnet }} block production is critically low
    expr: avg by (testnet) (increase(Coda_Transition_frontier_max_blocklength_observed ${rule_filter} [${alerting_timeframe}])) < 1
    labels:
      severity: critical

  - alert: LowPeerCount
    annotations:
      description: Critically low peer count on testnet {{ $labels.testnet }}.
      summary: {{ $labels.testnet }} avg. peer count is critically low
    expr: avg by (testnet) (max_over_time(Coda_Network_peers ${rule_filter} [${alerting_timeframe}])) < 1
    labels:
      severity: critical

- name: Warnings
  rules:
  - alert: HighBlockGossipLatency
    annotations:
      description: High block gossip latency (ms) within {{ $labels.testnet }} testnet.
      summary: '{{ $labels.testnet }} block gossip latency is high'
    expr: avg by (testnet) (max_over_time(Coda_Block_latency_gossip_time ${rule_filter} [${alerting_timeframe}])) > 200
    labels:
      severity: warning

  - alert: ZeroSnarkFeesObserved
    annotations:
      description: Transactions containing zero SNARK fees observed on testnet {{ $labels.testnet }} for more than 1 hour.
      summary: '{{ $labels.testnet }} SNARK work fees of zero Mina observed.'
    expr: max by (testnet) (Coda_Snark_work_snark_fee_bucket  ${rule_filter} [${alerting_timeframe}] == 0)
    labels:
      severity: warning
