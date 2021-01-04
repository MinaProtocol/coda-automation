global: {}
receivers:
  - name: ${pagerduty_receiver}
    pagerduty_configs:
      - service_key: ${pagerduty_service_key}
  - name: ${discord_alert_receiver}
    webhook_configs:
      - url: ${discord_alert_webhook}
route:
  receiver: ${discord_alert_receiver}
  group_by:
    - testnet
  routes:
    - receiver: ${pagerduty_receiver}
      match_re:
        testnet: ^(${pagerduty_alert_filter})$
