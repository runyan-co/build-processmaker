#!/usr/bin/env bash

#
# Installs ProcessMaker enterprise packages
#
installEnterprisePackages() {
  PACKAGES=$(php "$PM_SETUP_PATH/scripts/install-packages.php")

  for PACKAGE in $PACKAGES; do
    composer require "processmaker/$PACKAGE" --no-scripts --no-plugins --no-ansi --no-interaction
  done

  composer dumpautoload --no-ansi --no-interaction

  for PACKAGE in $PACKAGES; do
    php artisan "$PACKAGE:install" --no-ansi --no-interaction
    php artisan vendor:publish --tag="$PACKAGE" --no-ansi --no-interaction
  done
}

#
# setup the .env file(s)
#
setupEnvironment() {
  #
  # Setup local vars
  #
  PM_DOMAIN=localhost
  ENV_EXIST=false

  export PM_DOMAIN

  #
  # Await MySQL to be accessible
  #
  until mysqladmin ping -u pm -ppassword -h mysql --silent >/dev/null 2>&1; do
    sleep 1
  done

  #
  # Create the .env file
  #
  if [ ! -f .env ]; then
    cp .env.build .env
    ENV_EXIST=true
  fi

  #
  # Setup the http ports for the install command
  #
  if [ "${PM_APP_PORT}" != "80" ]; then
    PORT_WITH_PREFIX=":${PM_APP_PORT}"
  fi

  #
  # Make sure these are defined for use in the .env
  #
  if [ "$ENV_EXIST" = "false" ]; then
    {
      echo "APP_URL=http://${PM_DOMAIN}:${PM_APP_PORT}"
      echo "BROADCASTER_HOST=http://${PM_DOMAIN}:${PM_BROADCASTER_PORT}"
      echo "SESSION_DOMAIN=${PM_DOMAIN}"
      echo "NODE_BIN_PATH=$(which node)"
      echo "PROCESSMAKER_SCRIPTS_DOCKER=$(which docker)"
    } >>.env
  fi

  php artisan storage:link --no-interaction --no-ansi
  php artisan package:discover --no-interaction --no-ansi
  php artisan horizon:publish --no-interaction --no-ansi
}

#
# determine queue env
#
checkQueueServerEnv() {
  #
  # Default for entrypoint
  #
  QUEUE_SERVER=false

  #
  # determine if this is going to be a queue server
  #
  for ARG in "$@"; do
    if [ "1" = "$(echo "$ARG" | grep -c -m 1 -- "--queue")" ]; then
      QUEUE_SERVER=true
    fi
  done

  export QUEUE_SERVER
}

#
# Run the steps necessary to install the app
#
installProcessMaker() {
  #
  # Run the necessary artisan commands
  # to install the app
  #
  php artisan db:wipe --force --no-interaction --no-ansi
  php artisan telescope:publish --force --no-interaction --no-ansi
  php artisan migrate:fresh --force --no-interaction --no-ansi
  php artisan db:seed --force --no-interaction --no-ansi
  php artisan processmaker:build-script-executor php --no-interaction --no-ansi
  php artisan processmaker:build-script-executor javascript --no-interaction --no-ansi
  php artisan passport:install --no-interaction --no-ansi
}

#
# cache the config/events
#
cacheConfigs() {
  php artisan event:cache --no-interaction --no-ansi
  php artisan config:cache --no-interaction --no-ansi
}

#
# Source a few necessary env variables
#
if [ -f "/.env.setup" ]; then
  source "/.env.setup"
fi

#
# If we don't find a .env file and this is
# a web service, then we need to run the
# app's artisan install command
#
if [ ! -f ".env" ]; then
  #
  # setup the environment
  #
  checkQueueServerEnv "$@"
  setupEnvironment

  if [ "$QUEUE_SERVER" = "false" ]; then
    #
    # install the app if we're in the web
    # service container
    #
    installProcessMaker

    #
    # install the ProcessMaker-specific enterprise packages
    #
    installEnterprisePackages
  fi

  #
  # cache the app config and events
  #
  cacheConfigs
fi

#
# otherwise we wait for the web service to finish
# the installation and then start the queue
#
if [ "$QUEUE_SERVER" = "true" ]; then
  until curl http://host.docker.internal/api/docs; do
    echo "Waiting for web service to start..."
    sleep 5
  done
fi

#
# Spin up supervisor to run our
# in-container services
#
NPX_EXECUTABLE="$(which npx)" supervisord --nodaemon
