#!/usr/bin/env bash
if [ -f .env ]; then
  source .env
fi

export APP_CIPHER
export PM_BRANCH

PHP_VERSION=8.1
NODE_VERSION=16.18.1

APP=false
BASE=false
PACKAGES=false
WEB=false
QUEUE=false
ALL=false
INSTALLER=false

for ARG in "$@"; do
  if [ "1" = "$(echo "$ARG" | grep -c -m 1 -- "--web")" ]; then
    WEB=true
  fi
  if [ "1" = "$(echo "$ARG" | grep -c -m 1 -- "--queue")" ]; then
    QUEUE=true
  fi
  if [ "1" = "$(echo "$ARG" | grep -c -m 1 -- "--packages")" ]; then
    PACKAGES=true
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
  if [ "1" = "$(echo "$ARG" | grep -c -m 1 -- "--installer")" ]; then
    INSTALLER=true
  fi
done

if [ "$ALL" = "false" ] && \
  [ "$PACKAGES" = "false" ] && \
  [ "$APP" = "false" ] && \
  [ "$WEB" = "false" ] && \
  [ "$QUEUE" = "false" ] && \
  [ "$INSTALLER" = "false" ] && \
  [ "$BASE" = "false" ]; then \
  echo "No build arguments found" && exit 1
fi

{
  if [ "$BASE" = "true" ] || [ "$ALL" = "true" ]; then
    if ! docker image build \
      --build-arg PHP_VERSION="$PHP_VERSION" \
      --build-arg NODE_VERSION="$NODE_VERSION" \
      --build-arg GITHUB_OAUTH_TOKEN="$GITHUB_OAUTH_TOKEN" \
      --build-arg GITHUB_USERNAME="$GITHUB_USERNAME" \
      --build-arg GITHUB_EMAIL="$GITHUB_EMAIL" \
      --tag pm-v4-base:latest \
      --file=Dockerfile.base \
      --shm-size=128m \
      --compress .; then
        exit 1;
      fi
  fi

  if [ "$APP" = "true" ] || [ "$ALL" = "true" ]; then
    #
    # generate the .env file
    #
    rm -f .env.build
    cp .env.example .env.build
    echo "APP_KEY=$(php scripts/generate-app-key.php)" >>.env.build

    if ! docker image build \
      --build-arg PM_BRANCH="$PM_BRANCH" \
      --tag=pm-v4-app:latest \
      --shm-size=128m \
      --file=Dockerfile.app \
      --compress .; then
        rm .env.build && exit 1
    fi
  fi

  if [ "$PACKAGES" = "true" ] || [ "$ALL" = "true" ]; then
    export PM_COMPOSER_PACKAGES_BUILD_PATH="packages/"

    rm -rf "$PM_COMPOSER_PACKAGES_BUILD_PATH"
    cp -r "$PM_COMPOSER_PACKAGES_SOURCE_PATH/." "$PM_COMPOSER_PACKAGES_BUILD_PATH"

    if ! docker image build \
      --build-arg PM_BRANCH="$PM_BRANCH" \
      --build-arg PM_COMPOSER_PACKAGES_BUILD_PATH="$PM_COMPOSER_PACKAGES_BUILD_PATH" \
      --tag=pm-v4-packages:latest \
      --no-cache \
      --shm-size=256m \
      --file=Dockerfile.packages \
      --compress .; then
        rm -rf "$PM_COMPOSER_PACKAGES_BUILD_PATH" && exit 1;
      fi
  fi

  if [ "$INSTALLER" = "true" ] || [ "$ALL" = "true" ]; then
    if ! docker image build \
      --build-arg PM_BRANCH="$PM_BRANCH" \
      --tag=pm-v4-installer:latest \
      --shm-size=256m \
      --file=Dockerfile.installer \
      --no-cache=true \
      --compress .; then
        exit 1
    fi
  fi

  if [ "$WEB" = "true" ] || [ "$ALL" = "true" ]; then
    if ! docker image build \
      --build-arg PM_BRANCH="$PM_BRANCH" \
      --tag=pm-v4-web:latest \
      --shm-size=256m \
      --file=Dockerfile.web \
      --no-cache=true \
      --compress .; then
        exit 1
    fi
  fi

  if [ "$QUEUE" = "true" ] || [ "$ALL" = "true" ]; then
    if ! docker image build \
      --build-arg PM_BRANCH="$PM_BRANCH" \
      --tag=pm-v4-queue:latest \
      --shm-size=256m \
      --file=Dockerfile.queue \
      --no-cache=true \
      --compress .; then
        exit 1
    fi
  fi
}
