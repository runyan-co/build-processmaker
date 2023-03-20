#!/usr/bin/env bash

{
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
  # 1. Check for maintenance mode and continue when not in
  #    maintenance mode
  until checkForMaintenanceMode; do
    sleep 5
  done

  #
  # 3. Run the entrypoint command
  #
  bash -c "$PHP_FPM_BINARY --fpm-config /etc/php/$PHP_VERSION/fpm/php-fpm.conf --nodaemonize --allow-to-run-as-root"
}
