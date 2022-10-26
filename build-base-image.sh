#!/usr/bin/env bash

DOCKER_BUILDKIT=0 docker image build \
    --tag pm-v4-base:latest \
    --build-arg PM_VERSION=4.3.0-RC2 \
    --build-arg PHP_VERSION=8.1 \
    --build-arg NODE_VERSION=16 \
    --file Dockerfile.base .
