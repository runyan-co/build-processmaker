#!/usr/bin/env bash

{
  #
  # Check for the app .env and link it
  # when found, otherwise bail
  #
  setupEnv() {
    if [ ! -f "$PM_DIRECTORY/storage/keys/.env" ]; then
      echo "Queue .env file not found (env not ready)..." && sleep 1 && exit 0
    elif [ ! -f "$PM_DIRECTORY/.env" ]; then
      ln -s "$PM_DIRECTORY/storage/keys/.env" .env
    fi
  }

  #
  # Install composer dependencies only if
  # composer.json changes
  #
#  installComposerDepsIfNecessary() {
#    if [ "$(php "$PM_SETUP_PATH/scripts/generate-composer-hash.php")" = 1 ]; then
#      composer update -o --no-ansi --profile --no-interaction
#    fi
#  }

  #
  # If the app is in maintenance mode, bail
  #
  checkForMaintenanceMode() {
    if [ -f "$PM_DIRECTORY/storage/framework/maintenance.php" ]; then
      echo "ProcessMaker in maintenance mode..." && sleep 1 && exit 0
    fi
  }

  #
  # 1. Wait for the .env file (the installer service will place it
  #    in the storage:/var/www/html-/storage/keys directory)
  setupEnv

  #
  # 2. Check for maintenance mode and continue when not in
  #    maintenance mode
  checkForMaintenanceMode

  #
  # 3. Check if composer.json has changed and install if needed
  #
  composer update -o --no-ansi --profile --no-interaction

  #
  # 4. Run the entrypoint command and execute any user-passed
  #    arguments if found
  #
  if [ $# -gt 0 ]; then
    exec "$@"
  else
    bash -c '"$PHP_BINARY" "$PM_DIRECTORY/artisan" horizon --no-interaction --no-ansi'
  fi
}
