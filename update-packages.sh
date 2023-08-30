#!/usr/bin/env bash

#
# pull down the latest version of each branch for each
# local enterprise package and pull down the latest
# for core (processmaker/processmaker) too
#
{
  set -e
  source ./.env

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
