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
      NODE_OPTIONS=--max-old-space-size=8000 npm run dev --no-audit
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

  #
  # Install the executors
  #
  echo ""
  echo "Installing enterprise executors..."
  echo ""
  for EXECUTOR in docker-executor-csharp \
    docker-executor-java \
    docker-executor-php-ethos \
    docker-executor-python \
    docker-executor-python-selenium \
    docker-executor-r; do
      {
        docker compose exec -it php-fpm composer require "processmaker/$EXECUTOR"
        docker compose exec -it php-fpm php artisan "$EXECUTOR":install --no-ansi --no-interaction
        sleep 1
      }
  done;

}
