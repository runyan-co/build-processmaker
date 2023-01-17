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
  # 1. Wait for the .env file (the installer service will place it
  #    in the storage:/var/www/html-/storage/keys directory)
  #
  # 2. Check for maintenance mode and continue when not in
  #    maintenance mode
  until awaitInstallation && checkForMaintenanceMode; do
    sleep 5
  done

  #
  # Get the service container ids which would need
  # to be restarted if a file changes
  #
  getContainerIds() {
    docker container ps --filter status=running | grep 'cron\|queue\|php-fpm' | awk '{ print $1; }';
  }

  #
  # Restart specific services to reflect changes when a
  # file system event is detected
  #
  restartServices() {
    echo "Restarting service containers"
    docker container restart --time 0 $(getContainerIds);
  }

  #
  # Start watching for file changes and restart relevant
  # services when detected
  #
  watchFiles() {
    if node "$WATCH_JS_PATH"; then
      if restartServices; then
        return 0;
      fi
    fi
  }

  #
  # Run a loop to restart the file watcher if it
  # exits after a file change
  #
  while true; do
    if watchFiles; then
      echo "Cooling down";
      sleep 5;
    else
      echo "Error encountered, shutting down";
      exit 1;
    fi
  done
}
