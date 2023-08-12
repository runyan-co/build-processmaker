#!/usr/bin/env bash

{
  set -e
  source ./.env

  # Install the npm dependencies and built the
  # assets on the host machine due to an npm
  # dep issue within the docker image
  if [ ! -d "$PM_APP_SOURCE/node_modules" ]; then
    echo "Install npm dependencies and building assets..."
    cd "$PM_APP_SOURCE" && npm i --force
    cd "$PM_APP_SOURCE" && npm run dev --no-audit
  fi

  # Return to the docker build source directory
  # and attempt to build the base image and
  # run the docker compose services
  echo "Building docker image and deploying services..."
  cd "$PM_BUILD_SOURCE" && docker compose up -d --build

  # Exit when finished
  echo "Done!" && exit 0
}
