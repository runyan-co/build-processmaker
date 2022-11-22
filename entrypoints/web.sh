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
    if [ ! -d storage/keys ]; then
      mkdir -p storage/keys;
    fi

    #
    # Check for the app .env and link it
    # when found, otherwise bail
    #
    if [ ! -f storage/keys/.env ]; then
      echo "Queue .env file not found (env not ready)..." && sleep 1 && exit 0
    elif [ ! -f .env ]; then
      ln -s storage/keys/.env .env
    fi

    #
    # Check for the app composer.json
    # and link it if it's not already,
    # and if we don't find it, bail
    #
    if [ ! -f storage/framework/composer.json ]; then
      echo "Composer file not found (env not ready)..." && sleep 1 && exit 0
    fi

    if [ ! -L composer.json ]; then
      ln -s storage/framework/composer.json .
    fi
  }

  #
  # If the app is in maintenance mode, bail
  #
  checkForMaintenanceMode() {
    if [ -f storage/framework/maintenance.php ]; then
      echo "ProcessMaker in maintenance mode..." && sleep 3 && exit 0
    elif [ ! -f storage/framework/.installed ]; then
      echo "ProcessMaker installation not complete.." && sleep 3 && exit 0
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
  composer update -o --no-ansi --no-interaction

  #
  # 4. Run the entrypoint command and execute any user-passed
  #    arguments if found
  #
  if [ $# -gt 0 ]; then
    exec "$@"
  else
    bash -c 'NPX_EXECUTABLE="$(which npx)" supervisord --nodaemon'
  fi
}
