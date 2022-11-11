#!/usr/bin/env bash

#
# Installs ProcessMaker enterprise packages
#
installEnterprisePackages() {
  PACKAGES=$(php "$PM_SETUP_PATH/scripts/get-enterprise-package-names.php")

  for PACKAGE in $PACKAGES; do
    composer require "processmaker/$PACKAGE" --no-suggest --quiet --no-ansi --no-interaction
    php artisan "$PACKAGE:install" --no-ansi --no-interaction
    php artisan vendor:publish --tag="$PACKAGE" --no-ansi --no-interaction
  done

  composer dumpautoload -o --no-ansi --no-interaction --quiet
}

#
# setup the .env file(s)
#
setupEnvironment() {
  #
  # Setup local vars
  #
  export PM_DOMAIN=localhost

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

    #
    # Setup the http ports for the install command
    #
    if [ "${PM_APP_PORT}" != "80" ]; then
      PORT_WITH_PREFIX=":${PM_APP_PORT}"
    else
      PORT_WITH_PREFIX=""
    fi

    #
    # Make sure these are defined for use in the .env
    #
    {
      echo "APP_URL=http://${PM_DOMAIN}:${PM_APP_PORT}"
      echo "BROADCASTER_HOST=http://${PM_DOMAIN}:${PM_BROADCASTER_PORT}"
      echo "SESSION_DOMAIN=${PM_DOMAIN}"
      echo "HOME=${PM_DIRECTORY}"
      echo "NODE_BIN_PATH=$(which node)"
      echo "PROCESSMAKER_SCRIPTS_DOCKER=$(which docker)"
      echo "PROCESSMAKER_SCRIPTS_HOME=${PM_DIRECTORY}/storage/app/scripts"
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
# utility to remove substring from a string
#
removeLastString() {
  echo "${1%%$2}"
}

#
# Run the steps necessary to install the app
#
installProcessMaker() {
  php artisan telescope:publish --force --no-interaction --no-ansi
  php artisan migrate:fresh --no-interaction --no-ansi

  for SEEDER_FILENAME in $(ls "$PM_DIRECTORY/database/seeders" | grep -v "ScriptExecutor"); do
    SEEDER=$(removeLastString "$SEEDER_FILENAME" ".php")
    php artisan db:seed --class="$SEEDER" --no-interaction --no-ansi
  done

  php artisan passport:install --no-interaction --no-ansi

  #
  # build and install the script executors
  #
  buildScriptExecutors
}

#
# build and install the script executors
#
buildScriptExecutors() {
  php artisan docker-executor-php:install --no-interaction --no-ansi &
  php artisan docker-executor-node:install --no-interaction --no-ansi &
  php artisan docker-executor-lua:install --no-interaction --no-ansi &
  wait
  echo "Script executors built!"
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
# check if this is a queue server
#
checkQueueServerEnv "$@"

#
# If we don't find a .env file and this is
# a web service, then we need to run the
# app's artisan install command
#
if [ ! -f ".env" ]; then
  #
  # setup the environment
  #
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
# Spin up supervisor to run our
# in-container services
#
supervisord --nodaemon
