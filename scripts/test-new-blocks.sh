#!/bin/bash
# Trivial test to make sure blocks are being produced

SLOT_DURATION=$(coda client status -json | jq .consensus_configuration.slot_duration)
SLOT_DURATION_S=$(($SLOT_DURATION / 1000))
SLEEP_DURATION=$(($SLOT_DURATION_S / 3))

START=$(coda client status -json | jq .blockchain_length)
NOW="$START"

COUNTER=1
while [ "$NOW" -le "$START" ]; do
    NOW=$(coda client status -json | jq .blockchain_length)
    echo "Count: ${COUNTER}"
    echo "Block Height Now: ${NOW}"
    echo "Sleeping ${SLEEP_DURATION}s"
    sleep $SLEEP_DURATION
    COUNTER=$((COUNTER + 1))
    if [ "$COUNTER" -gt 10 ]; then
        echo 'Block test failed -- too much time passed without seeing a new block'
        exit 1
    fi
done

echo "Block test passed"
