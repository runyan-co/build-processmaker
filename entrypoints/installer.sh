#!/usr/bin/env bash

{
  #
  # Source a few necessary env variables
  #
  sourceDockerEnv() {
    if [ -f /.docker.env ]; then
      source /.docker.env
    fi
  }

  #
  # clone a copy of the platform repo
  #
  cloneGitRepo() {
    pm-cli output:header "Resetting git repo"
    git restore .
    git reset --hard HEAD^
  }

  #
  # removes any unnecessary previous build information
  #
  cleanBuildFiles() {
    rm -rf "$PM_DIR/storage/build/*"
    rm -rf "$PM_DIR/storage/build/.*"
  }

  #
  # Installs ProcessMaker enterprise packages
  #
  installEnterprisePackages() {
    PM_PACKAGES_DOTFILE=storage/build/.packages

    if [ ! -f "$PM_PACKAGES_DOTFILE" ]; then
      for PACKAGE in $(pm-cli packages:list); do
        {
          pm-cli output:header "Installing processmaker/$PACKAGE"
          composer require "processmaker/$PACKAGE" --quiet --no-ansi --no-plugins --no-interaction
          php artisan "$PACKAGE:install" --no-ansi --no-interaction
          php artisan vendor:publish --tag="$PACKAGE" --no-ansi --no-interaction
          echo "$PACKAGE" >>"$PM_PACKAGES_DOTFILE"
        }
      done

      composer dumpautoload -o --no-ansi --no-interaction
      pm-cli output:header "Enterprise packages installed"
    else
      pm-cli output:header "Enterprise packages already installed"
    fi
  }

  #
  # setup the .env file(s)
  #
  setupEnvironment() {
    #
    # Create and link the .env file
    #
    pm-cli output:header "Setting up environment"

    if [ ! -f .env ]; then
      cp "$PM_SETUP_DIR/.env.example" .env
    fi

    #
    # Make sure these are defined for use in the .env
    #
    if ! grep "APP_URL=http://${PM_DOMAIN}" <.env; then
      #
      # append the port to the app url if it's not port 80
      #
      if [ "$PM_APP_PORT" = 80 ] || [ "$PM_APP_PORT" = "80" ]; then
        PM_APP_URL_WITH_PORT="http://${PM_DOMAIN}"
      else
        PM_APP_URL_WITH_PORT="http://${PM_DOMAIN}:${PM_APP_PORT}"
      fi

      {
        echo "APP_URL=$PM_APP_URL_WITH_PORT"
        echo "BROADCASTER_HOST=http://${PM_DOMAIN}:${PM_BROADCASTER_PORT}"
        echo "SESSION_DOMAIN=${PM_DOMAIN}"
        echo "HOME=${PM_DIR}"
        echo "NODE_BIN_PATH=$(which node)"
        echo "PROCESSMAKER_SCRIPTS_DOCKER=$(which docker)"
        echo "PROCESSMAKER_SCRIPTS_HOME=${PM_DIR}/storage/app/scripts"
        echo "DB_USERNAME=$DB_USERNAME"
        echo "DB_HOST=$DB_HOST"
        echo "DB_HOSTNAME=$DB_HOSTNAME"
        echo "DB_PASSWORD=$DB_PASSWORD"
        echo "DATA_DB_HOST=$DATA_DB_HOST"
        echo "DATA_DB_USERNAME=$DATA_DB_USERNAME"
        echo "DATA_DB_PASSWORD=$DATA_DB_PASSWORD"
        echo "DATA_DB_PORT=$DATA_DB_PORT"
      } >>.env
    fi
  }

  #
  # utility to remove substring from a string
  #
  removeLastString() {
    echo "${1%%$2}"
  }

  #
  # Copy laravel echo server config
  #
  copyEchoServerConfig() {
    cp "$PM_SETUP_DIR/laravel-echo-server.json" .
  }

  #
  # Install app's composer dependencies
  #
  installComposerDeps() {
    pm-cli output:header "Installing composer dependencies"

    composer install \
      --no-progress \
      --optimize-autoloader \
      --no-scripts \
      --no-plugins \
      --no-ansi \
      --no-interaction

    composer clear-cache --no-ansi --no-interaction
  }

  #
  # Install app's npm dependencies
  #
  installNpmDeps() {
    pm-cli output:header "Installing npm dependencies"
    npm clean-install --no-audit
    pm-cli output:header "Compiling npm assets"
    npm run dev --no-progress
    npm cache clear --force
  }

  #
  # Run the steps necessary to install the app
  #
  installApplication() {
    #
    # Setup configuration files
    #
    copyEchoServerConfig

    #
    # Install deps in parallel
    #
    installComposerDeps
    installNpmDeps

    #
    # run the remaining artisan commands
    # to setup the application
    #
    php artisan key:generate --no-interaction --no-ansi
    php artisan package:discover --no-interaction --no-ansi
    php artisan horizon:publish --no-interaction --no-ansi
    php artisan telescope:publish --force --no-interaction --no-ansi
    php artisan db:wipe --no-interaction --no-ansi
    php artisan migrate:fresh --force --no-interaction --no-ansi
    php artisan db:seed --force --no-interaction --no-ansi
    php artisan passport:install --no-interaction --no-ansi
    php artisan storage:link --no-interaction --no-ansi
    php artisan telescope:publish --force --no-interaction --no-ansi
  }

  #
  # Wait for MySQL to come online
  #
  awaitMysql() {
    until mysqladmin ping -u "$DB_USERNAME" -P "$DB_PORT" -p"$DB_PASSWORD" -h "$DB_HOST" >/dev/null 2>&1; do
      echo "Waiting for mysql..." && sleep 1
    done
  }

  #
  # Install steps
  #
  installProcessMaker() {
    #
    # removes any unnecessary previous build information
    #
    cleanBuildFiles

    #
    # clone a fresh copy of the core repo
    #
    cloneGitRepo

    #
    # setup the environment
    #
    if ! setupEnvironment; then
      pm-cli output:error "Could not setup environment" && exit 1
    fi

    #
    # Wait for MySQL to come online
    #
    awaitMysql

    #
    # install the app if we're in the web
    # service container
    #
    if ! installApplication; then
      pm-cli output:error "Could not install ProcessMaker" && exit 1
    fi

    #
    # Mark as installed
    #
    touch storage/install/.installed && chmod 500 storage/install/.installed
  }

  #
  # entrypoint function
  #
  entrypoint() {
    #
    # Source a few necessary env variables
    #
    sourceDockerEnv

    #
    # If we don't find a linked .env file and this is
    # a web service, then we need to run the
    # app's artisan install command
    #
    if [ ! -f storage/install/.installed ]; then
      echo "" >storage/build/install.log

      if ! installProcessMaker | tee -a storage/build/install.log; then
        pm-cli output:error "Install failed. See storage/build/install.log for details." && exit 1
      fi
    fi
  }

  entrypoint && exec "$@"
}
