#!/bin/bash

set -e

docker build -t codaprotocol/coda-automation:manual .
docker push codaprotocol/coda-automation:manual
