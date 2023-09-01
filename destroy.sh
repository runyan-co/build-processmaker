#!/usr/bin/env bash

{
  set -e
  source ./.env

  # Bring down the docker services and destroy the volumes
  echo "Bringing down docker compose services..."
  docker compose down --remove-orphans --volumes --remove-orphans

  # Remove the installed dependencies
  echo "Removing node_modules/ and vendor/ directories..."
  rm -rf "$PM_APP_SOURCE/node_modules"
  rm -rf "$PM_APP_SOURCE/vendor"
  rm "$PM_APP_SOURCE/.env"

  # Restore the public directory and composer files
  echo "Restoring processmaker/processmaker back to git commit HEAD..."

  # Restore the rest of the app source dir...
  cd "$PM_APP_SOURCE" && git restore . && \
  cd "$PM_APP_SOURCE" && git restore --staged . && \
  cd "$PM_APP_SOURCE" && git clean -f -x && \
  cd "$PM_BUILD_SOURCE"

  # exit when complete
  echo "Done!" && exit 0
}
