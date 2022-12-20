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
      echo "App env file not found (env not ready)..."
      sleep 1 && exit 0
    fi

    #
    # copy over the .env
    #
    rm .env && cp storage/build/.env .env

    #
    # add container-specific env variables
    # to the app .env file
    #
    {
      echo "DB_USERNAME=$DB_USERNAME";
      echo "DB_HOST=$DB_HOST";
      echo "DB_HOSTNAME=$DB_HOSTNAME";
      echo "DB_PASSWORD=$DB_PASSWORD";
      echo "DATA_DB_HOST=$DATA_DB_HOST";
      echo "DATA_DB_USERNAME=$DATA_DB_USERNAME";
      echo "DATA_DB_PASSWORD=$DATA_DB_PASSWORD";
      echo "DATA_DB_PORT=$DATA_DB_PORT";
    } >>.env

    #
    # Check for the app composer.json
    # and link it if it's not already,
    # and if we don't find it, bail
    #
    for EXT in "json" "lock"; do
      if [ ! -f "storage/build/composer.$EXT" ]; then
        echo "Composer.$EXT not found (app not fully installed). Restarting..."
        sleep 1 && exit 0
      fi

      if [ ! -L "composer.$EXT" ]; then
        ln -s "storage/build/composer.$EXT" .
      fi
    done;
  }

  #
  # If the app is in maintenance mode, bail
  #
  checkForMaintenanceMode() {
    if [ -f storage/framework/maintenance.php ]; then
      echo "ProcessMaker in maintenance mode..."
      sleep 3 && exit 0
    elif [ ! -f storage/build/.installed ]; then
      echo "ProcessMaker installation not complete.."
      sleep 3 && exit 0
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
  # 4. Run the entrypoint command
  #
  bash -c '"$PHP_BINARY" "artisan" horizon --no-interaction --no-ansi'
}
