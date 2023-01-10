#!/usr/bin/env bash

{
  #
  # Make sure application is installed and ready
  #
  awaitInstallation() {
    #
    # Check for the app .env and link it
    # when found, otherwise bail
    #
    if [ ! -f storage/build/.env ]; then
      echo "App env file not found (env not ready)..."
      return 1
    elif [ ! -f storage/build/.installed ]; then
      echo "ProcessMaker installation not complete.."
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
  # loop every 60 sec instead of using cron
  #
  runArtisanSchedule() {
    bash -c '"$PHP_BINARY" "artisan" schedule:run --no-interaction --no-ansi';
    sleep 60;
    runArtisanSchedule;
  }

  #
  # 1. Wait for the .env file (the installer service will place it
  #    in the storage:/var/www/html-/storage/keys directory)
  #
  # 2. Check for maintenance mode and continue when not in
  #    maintenance mode
  until awaitInstallation && checkForMaintenanceMode; do
    sleep 5;
  done

  #
  # 3. Run the entrypoint command
  #
  runArtisanSchedule;
}
