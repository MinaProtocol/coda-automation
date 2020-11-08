#!/bin/bash

set -e

echo "====="
echo "Restart nodes: $RESTART_NODES every $RESTART_EVERY_MINS minutes"
echo "Make reports: $MAKE_REPORTS every $MAKE_REPORT_EVERY_MINS minutes to $MAKE_REPORT_DISCORD_WEBHOOK_URL"
echo "====="

if [ -z "${RESTART_NODES}" ] && [ "$RESTART_NODES" != "false" ]; then
  python3 /scripts/random_restart.py -n '' -i $RESTART_EVERY_MINS -ic true &
fi

if [ -z "${MAKE_REPORTS}" ] && [ "$MAKE_REPORTS" != "false" ]; then
  while true; do
    sleep $MAKE_REPORT_EVERY_MINS
    python3 make_report.py -n '' -ic --discord_webhook_url $MAKE_REPORT_DISCORD_WEBHOOK_URL
  done &
fi

sleep infinity
