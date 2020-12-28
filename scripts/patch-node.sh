#!/bin/bash

node=whale-block-producer-1
#node=whale-block-producer-15
#node=fish-block-producer-1

IMAGE="gcr.io/o1labs-192920/coda-daemon-baked:0.1.0-beta1-56b97f1-turbo-pickles-88f3b12"

PATCH="spec:
  template:
    spec:
      containers:
        - name: coda
          image: $IMAGE"

kubectl patch deploy/$node -p "$PATCH"
ready=""
while [[ -z $ready ]]; do
  ready=$(kubectl get pods -l app=$node | grep -P '\s+([1-9]+)\/\1\s+')
  kubectl get pods -l app=$node
  sleep 30
done
