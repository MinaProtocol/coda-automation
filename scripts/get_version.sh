#!/bin/bash

namespace=$1
pod=$(kubectl get pods -n $namespace | sed -n '2 p' | awk '{print $1;}')

#kubectl -n $namespace exec -c coda -i $pod -- coda -version
kubectl -n $namespace exec -c coda -i $pod -- apt list coda-testnet-postake-medium-curves 2>/dev/null | sed -n '2 p' | sed 's/.*from: //' | sed 's/]//'

