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
  # Change to desired processmaker/processmaker version
  #
  switchProcessMakerVersion() {
    git restore .
    git clean -d -f
    git fetch origin "$PM_BRANCH"
    git checkout "$PM_BRANCH"
  }

  #
  # Installs ProcessMaker enterprise packages
  #
  installEnterprisePackages() {
    PM_PACKAGES_DOTFILE=storage/build/.packages

    echo "";
    echo "+----------------------------------------------------------"
    echo "|"
    echo "|    Installing enterprise packages";
    echo "|"
    echo "+----------------------------------------------------------"
    echo "";

    if [ ! -f "$PM_PACKAGES_DOTFILE" ]; then
      for PACKAGE in $(pm-cli packages:list); do
        {
          echo "";
          echo "+----------------------------------------------------------"
          echo "|"
          echo "|    Installing processmaker/$PACKAGE";
          echo "|"
          echo "+----------------------------------------------------------"
          echo "";

          composer require "processmaker/$PACKAGE" --quiet --no-ansi --no-plugins --no-interaction;

          php artisan "$PACKAGE:install" --no-ansi --no-interaction;
          php artisan vendor:publish --tag="$PACKAGE" --no-ansi --no-interaction;

          echo "$PACKAGE" >>"$PM_PACKAGES_DOTFILE";
        }
      done

      composer dumpautoload -o --no-ansi --no-interaction

      echo "";
      echo "+----------------------------------------------------------"
      echo "|"
      echo "|    Enterprise packages installed";
      echo "|"
      echo "+----------------------------------------------------------"
      echo "";
    else
      echo "";
      echo "+----------------------------------------------------------"
      echo "|"
      echo "|    Enterprise packages already installed";
      echo "|"
      echo "+----------------------------------------------------------"
      echo "";
    fi
  }

  #
  # setup the .env file(s)
  #
  setupEnvironment() {
    #
    # Create and link the .env file
    #
    ENV_REALPATH=storage/build/.env

    echo "";
    echo "+----------------------------------------------------------"
    echo "|"
    echo "|    Setting up environment";
    echo "|"
    echo "+----------------------------------------------------------"
    echo "";

    if [ ! -f "$ENV_REALPATH" ]; then
      cp "$PM_SETUP_DIR/.env.example" "$ENV_REALPATH"
    elif [ ! -L .env ]; then
      ln -s "$ENV_REALPATH" .env
    fi

    #
    # Make sure these are defined for use in the .env
    #
    if ! grep "APP_URL=http://${PM_DOMAIN}:${PM_APP_PORT}" < .env; then
      {
        echo "APP_URL=http://${PM_DOMAIN}:${PM_APP_PORT}"
        echo "BROADCASTER_HOST=http://${PM_DOMAIN}:${PM_BROADCASTER_PORT}"
        echo "SESSION_DOMAIN=${PM_DOMAIN}"
        echo "HOME=${PM_DIR}"
        echo "NODE_BIN_PATH=$(which node)"
        echo "PROCESSMAKER_SCRIPTS_DOCKER=$(which docker)"
        echo "PROCESSMAKER_SCRIPTS_HOME=${PM_DIR}/storage/app/scripts"
      } >>"$ENV_REALPATH"
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
  # Move composer files to storage, then link it
  #
  linkComposerFiles() {
    for FILE in "composer.json" "composer.lock"; do
      if [ ! -L "$FILE" ]; then
        if [ -f "storage/build/$FILE" ]; then
          rm -rf "storage/build/$FILE"
        fi

        mv "$FILE" storage/build
        ln -s "storage/build/$FILE" .
      fi
    done;
  }

  #
  # Install app's composer dependencies
  #
  installComposerDeps() {
    echo "";
    echo "+----------------------------------------------------------";
    echo "|";
    echo "|    Installing composer dependencies";
    echo "|";
    echo "+----------------------------------------------------------";
    echo "";

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
    echo "";
    echo "+----------------------------------------------------------"
    echo "|"
    echo "|    Installing npm dependencies";
    echo "|"
    echo "+----------------------------------------------------------"
    echo "";

    npm clean-install --no-audit

    echo "";
    echo "+----------------------------------------------------------"
    echo "|"
    echo "|    Compiling npm assets";
    echo "|"
    echo "+----------------------------------------------------------"
    echo "";

    npm run dev --no-progress
    npm cache clear --force
  }

  #
  # Run the steps necessary to install the app
  #
  installApplication() {
    #
    # Cleanup
    #
    switchProcessMakerVersion

    #
    # Setup configuration files
    #
    linkComposerFiles
    copyEchoServerConfig

    #
    # Install deps in parallel
    #
    installComposerDeps &
    installNpmDeps &

    #
    # Wait for the deps to finish installing
    # and for the assets to be compiled
    #
    wait;

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
    until mysqladmin ping -u root -ppassword -h mysql >/dev/null 2>&1; do
      echo "Waiting for mysql..." && sleep 1
    done
  }

  #
  # Install steps
  #
  installProcessMaker() {
    #
    # Wait for MySQL to come online
    #
    awaitMysql

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
    if ! installApplication; then
      echo "Could not install ProcessMaker" && exit 1
    fi

    #
    # Make sure this is defined
    #
    if [ -n "$PM_INSTALL_ENTERPRISE_PACKAGES" ]; then
      export PM_INSTALL_ENTERPRISE_PACKAGES=true
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
    # Mark as installed
    #
    touch storage/build/.installed
  }

  #
  # Source a few necessary env variables
  #
  sourceDockerEnv

  #
  # If we don't find a linked .env file and this is
  # a web service, then we need to run the
  # app's artisan install command
  #
  if [ ! -f storage/build/.installed ]; then
    echo "" > storage/build/install.log

    if ! installProcessMaker | tee -a storage/build/install.log; then
      echo "Install failed. See storage/build/install.log for details." && exit 1
    fi
  fi

  exec "$@"
}
