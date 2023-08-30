#!/usr/bin/env bash

#
# pull down the latest version of each branch for each
# local enterprise package and pull down the latest
# for core (processmaker/processmaker) too
#
{
  set -e
  source ./.env

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

  # Reset and update the enterprise packages
  ./update-packages.sh
}
