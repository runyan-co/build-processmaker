#!/usr/bin/env bash

#
# pull down the latest version of each branch for each
# local enterprise package and pull down the latest
# for core (processmaker/processmaker) too
#
{
  set -e
  source ./.env

  for PACKAGE in "$PM_COMPOSER_PACKAGES_SOURCE_PATH/*"; do
    {
      cd "$PM_COMPOSER_PACKAGES_SOURCE_PATH/$PACKAGE_DIR"
      git restore .
      git restore . --staged
      git clean -f -x
      echo "$PACKAGE_DIR cleaned up and updated to the latest."
      exit 0
    } &
  done
}
