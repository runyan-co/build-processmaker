#!/usr/bin/env bash

{
  set -e
  source ./.env

  #
  # pull down the latest version of each branch for each
  # local enterprise package and pull down the latest
  # for core (processmaker/processmaker) too
  #
  {
    cd "$PM_APP_SOURCE"
    rm -rf ./vendor && \
    rm -rf ./node_modules && \
    git restore . && \
    git restore . --staged && \
    git clean -f -x && \
    git fetch --all && \
    git pull
  } & wait

  #
  # pull down the latest version of each branch for each
  # local enterprise package and pull down the latest
  # for core (processmaker/processmaker) too
  #
    for PACKAGE in $PM_COMPOSER_PACKAGES_SOURCE_PATH/*; do
      {
        cd "$PACKAGE" && git restore . && \
        cd "$PACKAGE" && git restore . --staged && \
        cd "$PACKAGE" && git clean -f -x && \
        cd "$PACKAGE" && git fetch --all && \
        cd "$PACKAGE" && git pull;
      } &
    done

    wait
}
