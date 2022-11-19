#!/usr/bin/env bash
if [ ! -f .env ]; then
  cp .env.build .env
fi

source .env

export APP_CIPHER
export PM_BRANCH
export PM_INSTALL_ENTERPRISE_PACKAGES

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
    #
    # Base
    #
    if ! docker image build \
      --build-arg PHP_VERSION="$PHP_VERSION" \
      --build-arg NODE_VERSION="$NODE_VERSION" \
      --build-arg GITHUB_OAUTH_TOKEN="$GITHUB_OAUTH_TOKEN" \
      --build-arg GITHUB_USERNAME="$GITHUB_USERNAME" \
      --build-arg GITHUB_EMAIL="$GITHUB_EMAIL" \
      --build-arg PM_APP_PORT="$PM_APP_PORT" \
      --build-arg PM_BROADCASTER_PORT="$PM_BROADCASTER_PORT" \
      --build-arg PM_DOCKER_SOCK="$PM_DOCKER_SOCK" \
      --build-arg PM_DOMAIN="$PM_DOMAIN" \
      --tag pm-v4-base:latest \
      --file=Dockerfile.base \
      --shm-size=512m \
      --compress .; then
        exit 1;
      fi
  fi

  if [ "$APP" = "true" ] || [ "$ALL" = "true" ]; then
    #
    # App
    #
    cp stubs/.env.example .
    cp ~/snippets/processmaker/GenerateUsers.php .

    echo "APP_KEY=$(php scripts/generate-app-key.php)" >>.env.example

    if ! docker image build \
      --build-arg PM_BRANCH="$PM_BRANCH" \
      --tag=pm-v4-app:latest \
      --shm-size=512m \
      --file=Dockerfile.app \
      --compress .; then
        rm .env.example
        rm GenerateUsers.php
        exit 1
    fi

    rm .env.example
    rm GenerateUsers.php
  fi

  if [ "$PACKAGES" = "true" ] || [ "$ALL" = "true" ]; then
    #
    # Packages
    #
    export PM_COMPOSER_PACKAGES_BUILD_PATH="packages/"

    removePackages() {
      rm -rf "$PM_COMPOSER_PACKAGES_BUILD_PATH"
    }

    removePackages
    cp -r "$PM_COMPOSER_PACKAGES_SOURCE_PATH/." "$PM_COMPOSER_PACKAGES_BUILD_PATH"

    if ! docker image build \
      --build-arg PM_BRANCH="$PM_BRANCH" \
      --build-arg PM_COMPOSER_PACKAGES_BUILD_PATH="$PM_COMPOSER_PACKAGES_BUILD_PATH" \
      --build-arg PM_INSTALL_ENTERPRISE_PACKAGES="$PM_INSTALL_ENTERPRISE_PACKAGES" \
      --tag=pm-v4-packages:latest \
      --no-cache \
      --shm-size=512m \
      --file=Dockerfile.packages \
      --compress .; then
        removePackages && exit 1;
      fi

      removePackages
  fi

  if [ "$INSTALLER" = "true" ] || [ "$ALL" = "true" ]; then
    #
    # Installer
    #
    if ! docker image build \
      --build-arg PM_BRANCH="$PM_BRANCH" \
      --tag=pm-v4-installer:latest \
      --shm-size=512m \
      --file=Dockerfile.installer \
      --no-cache=true \
      --compress .; then
        exit 1
    fi
  fi

  if [ "$WEB" = "true" ] || [ "$ALL" = "true" ]; then
    #
    # Web
    #
    if ! docker image build \
      --build-arg PM_BRANCH="$PM_BRANCH" \
      --tag=pm-v4-web:latest \
      --shm-size=512m \
      --file=Dockerfile.web \
      --no-cache=true \
      --compress .; then
        exit 1
    fi
  fi

  if [ "$QUEUE" = "true" ] || [ "$ALL" = "true" ]; then
    #
    # Queue
    #
    if ! docker image build \
      --build-arg PM_BRANCH="$PM_BRANCH" \
      --tag=pm-v4-queue:latest \
      --shm-size=512m \
      --file=Dockerfile.queue \
      --no-cache=true \
      --compress .; then
        exit 1
    fi
  fi
}
