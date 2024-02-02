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
  echo ""
  echo "Wait for remaining install commands to finish..."
  echo ""
  docker compose logs -f installer
  sleep 1
  docker compose exec -it queue php artisan package-pm-blocks:sync-pm-blocks --no-interaction
  sleep 1
  docker compose exec -it queue php artisan processmaker:sync-default-templates --no-interaction
  sleep 1
  docker compose exec -it queue php artisan processmaker:sync-guided-templates --no-interaction
  sleep 1
  docker compose exec -it queue php artisan config:clear --no-interaction
  sleep 1
  docker compose exec -it queue php artisan upgrade --no-interaction
  sleep 1
  docker compose exec -it queue php artisan config:cache --no-interaction
  sleep 3
  docker compose exec -it queue php artisan processmaker:regenerate-css --no-interaction

  echo ""
  echo "Done!"
  echo ""
}
