#!/bin/bash

ready=""
while [[ -z $ready ]]; do
  ready=$(kubectl get pods -l app=whale-block-producer-2 | grep -P '\s+([1-9]+)\/\1\s+')
  kubectl get pods -l app=whale-block-producer-2
  sleep 30
done


for whale in whale-block-producer-{3..15}; do
  kubectl patch deploy/${whale} -p "$(cat patch.yaml)"
  ready=""
  while [[ -z $ready ]]; do
    ready=$(kubectl get pods -l app=${whale} | grep -P '\s+([1-9]+)\/\1\s+')
    kubectl get pods -l app=${whale}
    sleep 30
  done
done
