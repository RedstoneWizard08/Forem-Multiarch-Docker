#!/bin/bash

docker buildx build -t redstonewizard/forem:development -f Dockerfile \
    --progress plain --target development .

docker buildx build -t redstonewizard/forem:production -f Dockerfile \
    --progress plain --target production .

docker buildx build -t redstonewizard/forem:testing -f Dockerfile \
    --progress plain --target testing .

if [[ "$*" == *"--push"* ]]; then
    docker push --all redstonewizard/forem
fi
