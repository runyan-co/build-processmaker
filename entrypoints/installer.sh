#!/usr/bin/env bash

{
  #
  # Installs ProcessMaker enterprise packages
  #
  installEnterprisePackages() {
    PM_PACKAGES_DOTFILE="$PM_DIRECTORY/storage/framework/.packages-installed"
    PM_PACKAGES=$(php "$PM_SETUP_PATH/scripts/get-enterprise-package-names.php")

    if [ ! -f "$PM_PACKAGES_DOTFILE" ]; then
      $PM_PACKAGES > "$PM_PACKAGES_DOTFILE"

      for PACKAGE in $PM_PACKAGES; do
        {
          echo "Installing processmaker/$PACKAGE..."
          composer require "processmaker/$PACKAGE" --profile --no-suggest --no-ansi --no-interaction
          php artisan "$PACKAGE:install" --no-ansi --no-interaction
          php artisan vendor:publish --tag="$PACKAGE" --no-ansi --no-interaction
        }
      done

      composer dumpautoload --optimize-autoloader --no-ansi --no-interaction --profile
      echo "Enterprise packages installed!"
    else
      echo "Enterprise packages already installed"
    fi
  }

  #
  # setup the .env file(s)
  #
  setupEnvironment() {
    #
    # Create and link the .env file
    #
    ENV_REALPATH="$PM_DIRECTORY/storage/keys/.env"

    if [ ! -f "$ENV_REALPATH" ]; then
      mv .env.example "$ENV_REALPATH"
    fi

    ln -s "$ENV_REALPATH" ./.env

    #
    # Make sure these are defined for use in the .env
    #
    {
      echo "APP_URL=http://${PM_DOMAIN}:${PM_APP_PORT}";
      echo "BROADCASTER_HOST=http://${PM_DOMAIN}:${PM_BROADCASTER_PORT}";
      echo "SESSION_DOMAIN=${PM_DOMAIN}";
      echo "HOME=${PM_DIRECTORY}";
      echo "NODE_BIN_PATH=$(which node)";
      echo "PROCESSMAKER_SCRIPTS_DOCKER=$(which docker)";
      echo "PROCESSMAKER_SCRIPTS_HOME=${PM_DIRECTORY}/storage/app/scripts";
    } >>"$ENV_REALPATH"

    php artisan storage:link --no-interaction --no-ansi
  }

  #
  # utility to remove substring from a string
  #
  removeLastString() {
    echo "${1%%$2}"
  }

  #
  # build and install the script executors
  #
  buildScriptExecutors() {
    echo "Building script executors..."

    for LANG in "php" "node"; do
      DOCKER_BUILDKIT=0 php artisan docker-executor-"$LANG":install --no-interaction --no-ansi &
    done

    wait;

    echo "Script executors built!"
  }

  #
  # Run the artisan command to seed the database
  #
  seedDatabase() {
    for SEEDER_FILENAME in $(ls "$PM_DIRECTORY/database/seeders" | grep -v "ScriptExecutor"); do
      SEEDER=$(removeLastString "$SEEDER_FILENAME" ".php")
      php artisan db:seed --class="$SEEDER" --no-interaction --no-ansi
    done
  }

  #
  # Run the steps necessary to install the app
  #
  installProcessMaker() {
    php artisan telescope:publish --force --no-interaction --no-ansi;
    php artisan horizon:publish --no-interaction --no-ansi;
    php artisan db:wipe --no-interaction --no-ansi;
    php artisan migrate --force --no-interaction --no-ansi;

    #
    # Seed the database
    #
    seedDatabase;

    php artisan package:discover --no-interaction --no-ansi;
    php artisan passport:install --no-interaction --no-ansi;

    #
    # build and install the script executors
    #
    buildScriptExecutors;
  }

  #
  # Wait for MySQL to come online
  #
  awaitMysql() {
    until mysqladmin ping -u root -ppassword -h mysql >/dev/null 2>&1; do
      echo "Waiting for mysql..." && sleep 1
    done
  }

  #
  # Install steps
  #
  installation() {
    #
    # Wait for MySQL to come online
    #
    awaitMysql;

    #
    # If we don't find a linked .env file and this is
    # a web service, then we need to run the
    # app's artisan install command
    #
    if [ ! -L .env ] && [ -f .env.example ]; then
      #
      # Put app in maintenance mode
      #
      php artisan down

      #
      # setup the environment
      #
      if ! setupEnvironment; then
        echo "Could not setup environment" && exit 1
      fi

      #
      # install the app if we're in the web
      # service container
      #
      if ! installProcessMaker; then
        echo "Could not install ProcessMaker" && exit 1
      fi

      #
      # Make sure this is defined
      #
      if [ -n "$PM_INSTALL_ENTERPRISE_PACKAGES" ]; then
        PM_INSTALL_ENTERPRISE_PACKAGES=true
      fi

      #
      # install the ProcessMaker-specific enterprise packages, if desired
      #
      if [ "$PM_INSTALL_ENTERPRISE_PACKAGES" = true ]; then
        if ! installEnterprisePackages; then
          echo "Could not install enterprise packages" && exit 1
        fi
      fi

      #
      # Bring app back online
      #
      php artisan up
    fi
  }

  #
  # Source a few necessary env variables
  #
  if [ -f /.docker.env ]; then
    source /.docker.env
  fi

  #
  # Install steps for the app
  #
  installation
}
