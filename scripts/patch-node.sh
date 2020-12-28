#!/bin/bash

node=whale-block-producer-1
#node=whale-block-producer-15
#node=fish-block-producer-1

IMAGE="gcr.io/o1labs-192920/coda-daemon-baked:0.2.0-efc44df-testworld-af5e10e"

PATCH="spec:
  template:
    spec:
      containers:
        - name: coda
          image: $IMAGE"

for node in whale-block-producer-{1..5}; do
  kubectl patch deploy/$node -p "$PATCH"
done
#ready=""
#while [[ -z $ready ]]; do
#  ready=$(kubectl get pods -l app=$node | grep -P '\s+([1-9]+)\/\1\s+')
#  kubectl get pods -l app=$node
#  sleep 30
#done
