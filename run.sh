#!/bin/bash

if [[ "$*" == "--dev" ]]; then
    docker-compose down
    docker volume prune -f
fi

docker-compose pull
docker-compose up
