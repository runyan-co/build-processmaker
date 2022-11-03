#!/usr/bin/env sh
#set -ex

##
# Run the steps necessary to install the app
##
installProcessMaker() {
  #
  # Setup local vars
  #
  PM_DOMAIN=localhost
  PORT_WITH_PREFIX=""

  export PM_DOMAIN;

  ##
  # Await MySQL to be accessible
  ##
  until mysqladmin ping -u pm -ppass -h mysql --silent >/dev/null 2>&1; do
    sleep 1
  done

  ##
  # Create the .env file
  ##
  cp .env.example .env

  ##
  # Setup the http ports for the install command
  ##
  if [ "${PM_APP_PORT}" != "80" ]; then
    PORT_WITH_PREFIX=":${PM_APP_PORT}"
  fi

  ##
  # Make sure these are defined for use in the .env
  ##
  {
    echo "FILESYSTEM_DRIVER=local"
    echo "APP_URL=http://${PM_DOMAIN}:${PM_APP_PORT}"
    echo "BROADCASTER_HOST=${APP_URL}:${PM_BROADCASTER_PORT}"
    echo "SESSION_DOMAIN=${PM_DOMAIN}"
    echo "NODE_BIN_PATH=$(which node)"
    echo "PROCESSMAKER_SCRIPTS_DOCKER=$(which docker)"
  } >>.env

  ##
  # Run the necessary artisan commands
  # to install the app
  ##
  php artisan key:generate --no-interaction --no-ansi --force
  php artisan package:discover --no-interaction --no-ansi
  php artisan migrate:fresh --force --no-interaction --no-ansi

  for SEEDER in \
    "UserSeeder" \
    "AnonymousUserSeeder" \
    "PermissionSeeder" \
    "ProcessSystemCategorySeeder" \
    "GroupSeeder" \
    "ScreenTypeSeeder" \
    "CategorySystemSeeder" \
    "ScreenSystemSeeder" \
    "SignalSeeder"
    do
      php artisan db:seed --class="$SEEDER" --force --no-interaction --no-ansi
    done


#  php artisan processmaker:build-script-executor php --no-interaction --no-ansi
#  php artisan processmaker:build-script-executor javascript --no-interaction --no-ansi
#  php artisan processmaker:build-script-executor lua --no-interaction --no-ansi

  php artisan storage:link --no-interaction --no-ansi
  php artisan passport:install --no-interaction --no-ansi
  php artisan horizon:publish --no-interaction --no-ansi
  php artisan telescope:publish --force --no-interaction --no-ansi
  php artisan config:cache --no-interaction --no-ansi
}

##
# If we don't find a .env file, then we need to
# run the app's artisan install command
##
if [ ! -f ".env" ]; then
  installProcessMaker
fi

##
# Spin up supervisor to run our
# in-container services
##
NPX_EXECUTABLE="$(which npx)" supervisord --nodaemon
