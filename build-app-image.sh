#!/usr/bin/env bash

docker image build \
    --build-arg PM_VERSION="$PM_VERSION" \
    --tag=pm-v4:latest \
    --shm-size=256m \
    --file=Dockerfile \
    --compress .
