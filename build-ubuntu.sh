#!/bin/bash

set -e

docker buildx build -t redstonewizard/forem:ruby-ubuntu -f Dockerfile.ubuntu \
    --progress plain --target ruby --load . --cache-from=type=registry,ref=docker.kadaroja.com/redstonewizard08/forem-cache \
    --cache-to=type=registry,ref=docker.kadaroja.com/redstonewizard08/forem-cache

docker buildx build -t redstonewizard/forem:development-ubuntu -f Dockerfile.ubuntu \
    --progress plain --target development --load . --cache-from=type=registry,ref=docker.kadaroja.com/redstonewizard08/forem-cache \
    --cache-to=type=registry,ref=docker.kadaroja.com/redstonewizard08/forem-cache

docker buildx build -t redstonewizard/forem:production-ubuntu -f Dockerfile.ubuntu \
    --progress plain --target production --load . --cache-from=type=registry,ref=docker.kadaroja.com/redstonewizard08/forem-cache \
    --cache-to=type=registry,ref=docker.kadaroja.com/redstonewizard08/forem-cache

docker buildx build -t redstonewizard/forem:testing-ubuntu -f Dockerfile.ubuntu \
    --progress plain --target testing --load . --cache-from=type=registry,ref=docker.kadaroja.com/redstonewizard08/forem-cache \
    --cache-to=type=registry,ref=docker.kadaroja.com/redstonewizard08/forem-cache

if [[ "$*" == *"--push"* ]]; then
    docker push -a redstonewizard/forem
fi
