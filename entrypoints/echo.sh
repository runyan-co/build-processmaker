#!/usr/bin/env bash

{
  #
  # Make sure application is installed and ready
  #
  awaitInstallation() {
    #
    # Check for the requires packages files
    # to run the echo server
    #
    if [ ! -d node_modules ]; then
      echo "node_modules/ folder not ready (run npm i to install it)..."
      return 1
    elif [ ! -f node_modules/.bin/laravel-echo-server ]; then
      echo "Laravel echo server binary not ready..."
      return 1
    else
      return 0
    fi
  }

  #
  # If the app is in maintenance mode, bail
  #
  checkForMaintenanceMode() {
    if [ -f storage/framework/maintenance.php ]; then
      echo "ProcessMaker in maintenance mode..."
      return 1
    else
      return 0
    fi
  }

  #
  # Remove the echo lock file so we can start with a fresh one
  #
  removeLockFile() {
    if [ -f laravel-echo-server.lock ]; then
      rm -rf laravel-echo-server.lock;
    fi
  }

  #
  # 1. Wait for the .env file (the installer service will place it
  #    in the storage:/var/www/html-/storage/keys directory)
  #
  # 2. Check for maintenance mode and continue when not in
  #    maintenance mode
  until awaitInstallation && checkForMaintenanceMode; do
    sleep 5
  done

  #
  # 3. Remove any existing echo server lock file
  #
  removeLockFile;

  #
  # 4. Run the entrypoint command
  #
  bash -c 'npx /var/www/html/node_modules/.bin/laravel-echo-server start --force --dev';
}
