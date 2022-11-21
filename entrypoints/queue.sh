#!/usr/bin/env bash
set -e

{
  if [ ! -f "$PM_DIRECTORY/storage/keys/.env" ]; then
      echo "Queue .env file not found (env not ready)..." && \
      sleep 3 && \
      exit 0
  elif [ ! -f "$PM_DIRECTORY/.env" ]; then
      ln -s "$PM_DIRECTORY/storage/keys/.env" .env
  fi

  if [ -f "$PM_DIRECTORY/storage/framework/maintenance.php" ]; then
    echo "ProcessMaker in maintenance mode..." && \
    sleep 3 && \
    exit 0
  fi

  if [ "$(php "$PM_SETUP_PATH/scripts/generate-composer-hash.php")" = 1 ]; then
    composer install --optimize-autoloader --no-ansi --profile
  fi

  bash -c '"$PHP_BINARY" "$PM_DIRECTORY/artisan" horizon --no-interaction --no-ansi'
}
