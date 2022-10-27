#!/usr/bin/env bash
set -ex

installProcessMaker() {
  ##
  # Wait for mysql to become accessible
  ##
  while ! mysqladmin ping -u pm -ppass -h mysql --silent; do
    echo "Waiting for mysql"
    sleep 1
  done

  ##
  # Setup the http ports for the install command
  ##
  if [ "${PM_APP_PORT}" = "80" ]; then
    PORT_WITH_PREFIX=""
  else
    PORT_WITH_PREFIX=":${PM_APP_PORT}"
  fi

  ##
  # Make sure these are defined for use in the .env
  ##
  export DOCKER_PATH="$(which docker)"
  export NODE_PATH="$(which node)"
  export NPX_PATH="$(which npx)"

  ##
  # Copy the example .env file and run the necessary
  # artisan commands to install the app
  ##
  cp .env.example .env
  php artisan key:generate --no-interaction --no-ansi --force
  php artisan package:discover --no-interaction --no-ansi
  php artisan migrate --force --no-interaction --no-ansi
  php artisan db:seed --force --no-interaction --no-ansi
  php artisan passport:install --no-interaction --no-ansi
  php artisan storage:link --no-interaction --no-ansi
  php artisan horizon:assets --no-interaction --no-ansi
  php artisan processmaker:build-script-executor php --no-interaction --no-ansi
  php artisan processmaker:build-script-executor javascript --no-interaction --no-ansi
# php artisan processmaker:build-script-executor lua --no-interaction --no-ansi
  php artisan config:cache --no-interaction --no-ansi
}

##
# If we don't find a .env file, then we need to
# run the app's artisan install command
##
if [ ! -f ".env" ]; then
  installProcessMaker;
fi

##
# Run supervisor and then we're ready to go
##
{
  supervisord --nodaemon --configuration /etc/supervisor/conf.d/services.conf
}
