#!/usr/bin/env bash

docker image build \
    --build-arg PM_VERSION="$PM_VERSION" \
    --build-arg PHP_VERSION=8.1 \
    --build-arg NODE_VERSION=16.15.0 \
    --tag pm-v4-base:latest \
    --file=Dockerfile.base \
    --shm-size=256m \
    --compress .
