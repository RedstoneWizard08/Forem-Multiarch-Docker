#!/bin/bash

set -e

docker buildx build -t redstonewizard/forem:ruby -f Dockerfile \
    --progress plain --target ruby --load . --cache-from=type=registry,ref=docker.kadaroja.com/redstonewizard08/forem-cache \
    --cache-to=type=registry,ref=docker.kadaroja.com/redstonewizard08/forem-cache

docker buildx build -t redstonewizard/forem:development -f Dockerfile \
    --progress plain --target development --load . --cache-from=type=registry,ref=docker.kadaroja.com/redstonewizard08/forem-cache \
    --cache-to=type=registry,ref=docker.kadaroja.com/redstonewizard08/forem-cache

docker buildx build -t redstonewizard/forem:production -f Dockerfile \
    --progress plain --target production --load . --cache-from=type=registry,ref=docker.kadaroja.com/redstonewizard08/forem-cache \
    --cache-to=type=registry,ref=docker.kadaroja.com/redstonewizard08/forem-cache

docker buildx build -t redstonewizard/forem:testing -f Dockerfile \
    --progress plain --target testing --load . --cache-from=type=registry,ref=docker.kadaroja.com/redstonewizard08/forem-cache \
    --cache-to=type=registry,ref=docker.kadaroja.com/redstonewizard08/forem-cache

if [[ "$*" == *"--push"* ]]; then
    docker push -a redstonewizard/forem
fi
