#!/usr/bin/env sh
set -ex

export PM_VERSION="4.3.0-RC2"

ENTRY=false
APP=false
BASE=false
ALL=false
REMOVE=false

for ARG in "$@"; do
  if [ "1" = "$(echo "$ARG" | grep -c -m 1 -- "--rm")" ]; then
    REMOVE=true
  fi
  if [ "1" = "$(echo "$ARG" | grep -c -m 1 -- "--entry")" ]; then
    ENTRY=true
  fi
  if [ "1" = "$(echo "$ARG" | grep -c -m 1 -- "--app")" ]; then
    APP=true
  fi
  if [ "1" = "$(echo "$ARG" | grep -c -m 1 -- "--base")" ]; then
    BASE=true
  fi
  if [ "1" = "$(echo "$ARG" | grep -c -m 1 -- "--all")" ]; then
    ALL=true
  fi
done

{
  if [ "$BASE" = "true" ] || [ "$ALL" = "true" ]; then
    docker image build \
      --build-arg PM_VERSION="$PM_VERSION" \
      --build-arg PHP_VERSION=8.1 \
      --build-arg NODE_VERSION=16.15.0 \
      --tag pm-v4-base:latest \
      --file=Dockerfile.base \
      --shm-size=256m \
      --compress .
  fi

  if [ "$APP" = "true" ] || [ "$ALL" = "true" ]; then
    docker image build \
      --build-arg PM_VERSION="$PM_VERSION" \
      --tag=pm-v4-app:latest \
      --shm-size=256m \
      --file=Dockerfile.app \
      --compress .
  fi

  if [ "$ENTRY" = "true" ] || [ "$ALL" = "true" ]; then
    docker image build \
      --build-arg PM_VERSION="$PM_VERSION" \
      --tag=pm-v4:latest \
      --shm-size=256m \
      --file=Dockerfile \
      --no-cache=true \
      --compress .
  fi
}
