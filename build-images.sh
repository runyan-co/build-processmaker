#!/usr/bin/env bash
PM_BRANCH="feature/FOUR-6832"

export PM_BRANCH

ENTRY=false
APP=false
BASE=false
ALL=false

for ARG in "$@"; do
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

if [ "$ALL" = "false" ] && [ "$ENTRY" = "false" ] && \
   [ "$APP" = "false" ] && [ "$BASE" = "false" ]; then
  echo "No build arguments found" && exit 1
fi

{
  if [ "$BASE" = "true" ] || [ "$ALL" = "true" ]; then
    docker image build \
      --build-arg PHP_VERSION=8.1 \
      --build-arg NODE_VERSION=16.15.0 \
      --tag pm-v4-base:latest \
      --file=Dockerfile.base \
      --shm-size=256m \
      --compress .
  fi

  if [ "$APP" = "true" ] || [ "$ALL" = "true" ]; then
    docker image build \
      --build-arg PM_BRANCH="$PM_BRANCH" \
      --tag=pm-v4-app:latest \
      --shm-size=256m \
      --file=Dockerfile.app \
      --compress .
  fi

  if [ "$ENTRY" = "true" ] || [ "$ALL" = "true" ]; then
    docker image build \
      --build-arg PM_BRANCH="$PM_BRANCH" \
      --tag=pm-v4:latest \
      --shm-size=256m \
      --file=Dockerfile \
      --no-cache=true \
      --compress .
  fi
}
