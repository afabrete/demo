#!/bin/bash

echo "$REPOSITORY_PASSWORD" | docker login -u $REPOSITORY_USER ghcr.io --password-stdin

docker-compose -f ./iac/docker-compose.yml push
