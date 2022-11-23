#!/usr/bin/env bash

{
  #
  # Base app files/env setup
  #
  setupEnv() {
    #
    # Check for the app .env and link it
    # when found, otherwise bail
    #
    if [ ! -f storage/build/.env ]; then
      echo "App env file not found (env not ready)..." && sleep 1 && exit 0
    elif [ ! -L .env ]; then
      ln -s storage/build/.env .env
    fi

    #
    # Check for the app composer.json
    # and link it if it's not already,
    # and if we don't find it, bail
    #
    if [ ! -f storage/build/composer.json ] || [ ! -f storage/build/composer.lock ]; then
      echo "Composer file(s) not found (app not ready)..."
      sleep 1
      exit 0
    fi

    if [ ! -L composer.json ]; then
      ln -s storage/build/composer.json .
    fi

    if [ ! -L composer.lock ]; then
      ln -s storage/build/composer.lock .
    fi
  }

  #
  # If the app is in maintenance mode, bail
  #
  checkForMaintenanceMode() {
    if [ -f storage/framework/maintenance.php ]; then
      echo "ProcessMaker in maintenance mode..."
      sleep 3
      exit 0
    elif [ ! -f storage/build/.installed ]; then
      echo "ProcessMaker installation not complete.."
      sleep 3
      exit 0
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
  # 3. Run the entrypoint command
  bash -c 'NPX_EXECUTABLE="$(which npx)" supervisord --nodaemon'
}