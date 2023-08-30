#!/usr/bin/env bash

{
  set -e
  source ./.env

  # Install the npm dependencies and built the
  # assets on the host machine due to an npm
  # dep issue within the docker image
  if [ ! -d "$PM_APP_SOURCE/node_modules" ]; then
    {
      echo ""
      echo "Install npm dependencies and building assets..."
      echo ""
      cd "$PM_APP_SOURCE"
      npm install --unsafe-perm=true && \
      NODE_OPTIONS=--max-old-space-size=8000 npm run prod
    } & wait
  fi

  # Return to the docker build source directory
  # and attempt to build the base image and
  # run the docker compose services
  echo ""
  echo "Building docker image and deploying services..."
  echo ""
  docker compose up -d --build

  # Build is complete, show the logs for the installer
  docker compose logs -f installer
}
