#!/bin/bash

testnet_name=$1

# arguments are
# --docker-image= and --commit-hash=
while [ $# -gt 0 ]; do
  case "$1" in
    --docker-image=*)
      dimage="${1#*=}"
      ;;
    --commit-hash=*)
      commit_hash="${1#*=}"
      ;;
  esac
  shift
done

echo testnet is $testnet_name
echo docker image is codaprotocol/coda-daemon:$dimage
echo commit hash is $commit_hash
first7Commit=$(echo $commit_hash | cut -c1-7)
final_name=codaprotocol/coda-daemon-baked:$dimage-$first7Commit

output=$(cat bake/Dockerfile | docker build \
  --build-arg "BAKE_VERSION=$dimage" \
  --build-arg "COMMIT_HASH=$commit_hash" \
  --build-arg "TESTNET_NAME=$testnet_name" - | tee /dev/tty | tail -1)
baked_image=${output##* }

docker tag $baked_image $final_name
echo $final_name

