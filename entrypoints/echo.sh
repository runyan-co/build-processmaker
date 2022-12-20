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
    if [ ! -f .env ]; then
      echo "App env file not found (env not ready)..."
      sleep 1 && exit 0
    fi
  }

  #
  # If the app is in maintenance mode, bail
  #
  checkForMaintenanceMode() {
    if [ -f storage/framework/maintenance.php ]; then
      echo "ProcessMaker in maintenance mode..."
      sleep 3 && exit 0
    elif [ ! -f storage/install/.installed ]; then
      echo "ProcessMaker installation not complete.."
      sleep 3 && exit 0
    fi
  }

  #
  # Remove the echo lock file so we can start with a fresh one
  #
  removeLockFile() {
    if [ -f laravel-echo-server.lock ]; then
      rm -rf laravel-echo-server.lock
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
  # 3. Remove any existing echo server lock file
  #
  removeLockFile

  #
  # 4. Run the entrypoint command
  #
  bash -c 'npx /var/www/html/node_modules/.bin/laravel-echo-server start --force --dev'
}
