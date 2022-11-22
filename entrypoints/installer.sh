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
  # Installs ProcessMaker enterprise packages
  #
  installEnterprisePackages() {
    PM_PACKAGES_DOTFILE=storage/framework/.packages

    if [ ! -f "$PM_PACKAGES_DOTFILE" ]; then
      for PACKAGE in $(php "$PM_SETUP_PATH/scripts/get-enterprise-package-names.php"); do
        {
          echo "";
          echo "| ----------------------------------------------------------- |"
          echo "|                                                             |"
          echo "| Installing processmaker/$PACKAGE";
          echo "|                                                             |"
          echo "| ----------------------------------------------------------- |"
          echo "";

          composer require "processmaker/$PACKAGE" --no-ansi --no-plugins --no-interaction;

          php artisan "$PACKAGE:install" --no-ansi --no-interaction;
          php artisan vendor:publish --tag="$PACKAGE" --no-ansi --no-interaction;

          echo "$PACKAGE" >>"$PM_PACKAGES_DOTFILE";
        }
      done

      composer dumpautoload -o --no-ansi --no-interaction --profile
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
    ENV_REALPATH=storage/keys/.env

    if [ ! -f "$ENV_REALPATH" ]; then
      cp "$PM_SETUP_PATH/.env.example" "$ENV_REALPATH"
    fi

    if [ ! -L .env ]; then
      ln -s "$ENV_REALPATH" .env
    fi

    #
    # Make sure these are defined for use in the .env
    #
    if ! grep "APP_URL=http://${PM_DOMAIN}:${PM_APP_PORT}" < .env >/dev/null 2>&1; then
      {
        echo "APP_URL=http://${PM_DOMAIN}:${PM_APP_PORT}"
        echo "BROADCASTER_HOST=http://${PM_DOMAIN}:${PM_BROADCASTER_PORT}"
        echo "SESSION_DOMAIN=${PM_DOMAIN}"
        echo "HOME=${PM_DIRECTORY}"
        echo "NODE_BIN_PATH=$(which node)"
        echo "PROCESSMAKER_SCRIPTS_DOCKER=$(which docker)"
        echo "PROCESSMAKER_SCRIPTS_HOME=${PM_DIRECTORY}/storage/app/scripts"
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
    cp "$PM_SETUP_PATH/laravel-echo-server.json" .
  }

  #
  # Move the composer file to storage, then link it
  #
  linkComposerFile() {
    if [ ! -L composer.json ]; then
      mv composer.json storage/framework
      ln -s storage/framework/composer.json .
    fi
  }

  #
  # Install app's composer dependencies
  #
  installComposerDeps() {
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
    npm clean-install --no-audit
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
    linkComposerFile
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
    # Bring the app back up
    #
    php artisan up --no-interaction --no-ansi
    php artisan horizon:terminate --no-interaction --no-ansi

    #
    # Mark as installed
    #
    touch storage/framework/.installed
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
  if [ ! -f storage/framework/.installed ]; then
    if ! installProcessMaker | tee -a storage/framework/.install; then
      rm storage/framework/.install
      echo "Install failed"
      exit 1
    fi
  fi
}
