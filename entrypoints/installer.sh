#!/usr/bin/env bash

{
  #
  # Define this for use later
  #
  if [ -n "$INSTALL_ENTERPRISE_PACKAGES" ]; then
    export INSTALL_ENTERPRISE_PACKAGES=true
  fi

  #
  # Source a few necessary env variables
  #
  sourceDockerEnv() {
    if [ -f /.docker.env ]; then
      source /.docker.env;
    fi
  }

  #
  # restore public dir
  #
  restorePublicDirectory() {
    git restore ./public;
  }

  #
  # restore app-specific storage dir
  #
  restoreAppStorage() {
    git restore ./storage/app;
  }

  #
  # empty the ./vendor directory
  #
  emptyVendorDir() {
    [ -d ./vendor ] && rm -rf ./vendor;
  }

  #
  # empty the ./node_modules directory
  #
  emptyNodeModulesDir() {
    [ -d ./node_modules ] && rm -rf ./node_modules;
  }

  #
  # Installs ProcessMaker enterprise packages
  #
  installEnterprisePackages() {
    PACKAGES_DOTFILE=storage/build/.packages

    if [ ! -f "$PACKAGES_DOTFILE" ]; then
      for PACKAGE in $(pm-cli packages:list); do
        {
          # Let the user know which package is
          # being installed
          pm-cli output:header "Installing processmaker/$PACKAGE";

          # Use composer to require the package
          # we want to install
          composer require "processmaker/$PACKAGE" -vvv --no-ansi --no-plugins --no-interaction;

          # Run the related artisan install command
          # the package provides
          php artisan "$PACKAGE:install" --no-ansi --no-interaction;

          # Publish any assets or files the package provides
          php artisan vendor:publish --tag="$PACKAGE" --no-ansi --no-interaction;

          # Add the installed package to our
          # build dotfile for safekeeping
          echo "$PACKAGE" >>"$PACKAGES_DOTFILE";
        }
      done

      composer dumpautoload -vvv -o --no-ansi --no-interaction;
      pm-cli output:header "Enterprise packages installed";

    else
      pm-cli output:header "Enterprise packages already installed";
    fi
  }

  #
  # setup the .env file(s)
  #
  setupEnvironment() {
    ENV_REALPATH=storage/build/.env

    #
    # Create and link the .env file
    #
    pm-cli output:header "Setting up environment";

    if [ ! -f "$ENV_REALPATH" ]; then
      echo "Copying env setup file to build folder";
      cp "$PM_SETUP_DIR/.env.example" "$ENV_REALPATH";
    fi

    #
    # append the port to the app url if it's not port 80
    #
    if [ "$PM_APP_PORT" = 80 ] || [ "$PM_APP_PORT" = "80" ]; then
      PM_APP_URL_WITH_PORT="http://${PM_DOMAIN}"
    else
      PM_APP_URL_WITH_PORT="http://${PM_DOMAIN}:${PM_APP_PORT}"
    fi

    #
    # Make sure these are defined for use in the .env
    #
    {
      echo "APP_URL=${PM_APP_URL_WITH_PORT}";
      echo "BROADCASTER_HOST=http://${PM_DOMAIN}:${PM_BROADCASTER_PORT}";
      echo "SESSION_DOMAIN=${PM_DOMAIN}";
      echo "HOME=${PM_DIR}";
      echo "NODE_BIN_PATH=$(which node)";
      echo "PROCESSMAKER_SCRIPTS_DOCKER=$(which docker)";
      echo "PROCESSMAKER_SCRIPTS_HOME=${PM_DIR}/storage/app/scripts";
      echo "DB_HOST=${DB_HOST}";
      echo "DB_PORT=${DB_PORT}";
      echo "DB_HOSTNAME=${DB_HOST}";
      echo "DB_NAME=${DB_NAME}";
      echo "DB_USERNAME=${DB_USERNAME}";
      echo "DB_PASSWORD=${DB_PASSWORD}";
      echo "DATA_DB_HOST=${DB_HOST}";
      echo "DATA_DB_USERNAME=${DB_USERNAME}";
      echo "DATA_DB_PASSWORD=${DB_PASSWORD}";
      echo "DATA_DB_PORT=${DB_PORT}";
      echo "DATA_DB_NAME=${DB_NAME}";
    } >>"$ENV_REALPATH";

    if [ -f .env ]; then
      echo "Removing default .env file";
      rm -f .env;
    fi

    echo "Copying env file to app directory";
    cp "$ENV_REALPATH" .;
  }

  #
  # Install app's composer dependencies
  #
  installComposerDeps() {
    pm-cli output:header "Installing composer dependencies";

    composer install -vvv \
      --no-progress \
      --optimize-autoloader \
      --no-scripts \
      --no-plugins \
      --no-ansi \
      --no-interaction;

    composer clear-cache -vvv --no-ansi --no-interaction;
  }

  #
  # Install app's npm dependencies
  #
  npmInstallAndBuild() {
    pm-cli output:header "Installing npm dependencies";
    npm clean-install --no-audit;
    pm-cli output:header "Compiling npm assets";
    npm run dev --no-progress;
    npm cache clear --force;
  }

  #
  # Run the steps necessary to install the app
  #
  installApplication() {
    #
    # Install composer dependencies
    #
    if ! installComposerDeps; then
      pm-cli output:error "Error while installing composer dependencies" && exit 1;
    fi

    #
    # Install npm dependencies and run build
    #
    if ! npmInstallAndBuild; then
      pm-cli output:error "Error while installing npm dependencies or building assets" && exit 1;
    fi

    #
    # Run the remaining artisan commands to
    # finish the base installation
    #
    php artisan key:generate --no-interaction --no-ansi;
    php artisan package:discover --no-interaction --no-ansi;
    php artisan horizon:publish --no-interaction --no-ansi;
    php artisan telescope:publish --force --no-interaction --no-ansi;
    php artisan migrate:fresh --force --no-interaction --no-ansi;
    php artisan db:seed --force --no-interaction --no-ansi;
    php artisan passport:install --no-interaction --no-ansi;
    php artisan storage:link --no-interaction --no-ansi;
    php artisan telescope:publish --force --no-interaction --no-ansi;
  }

  #
  # Wait for MySQL to come online
  #
  awaitMysql() {
    until mysqladmin ping -u "$DB_USERNAME" -P "$DB_PORT" -p"$DB_PASSWORD" -h "$DB_HOST" >/dev/null 2>&1; do
      echo "Waiting for mysql..." && sleep 1;
    done
  }

  #
  # restore directories which were
  # emptied when persisted volumes
  # were mounted
  #
  restoreDirectories() {
    restorePublicDirectory;
    restoreAppStorage;
    emptyVendorDir;
    emptyNodeModulesDir;
  }

  #
  # Install steps
  #
  installProcessMaker() {
    #
    # Wait for MySQL to come online
    #
    awaitMysql;

    #
    # commands to restore directories
    # replaced by persisted volumes
    # when initialized
    #
    restoreDirectories;

    #
    # setup the environment
    #
    if ! setupEnvironment; then
      pm-cli output:error "Could not setup environment" && exit 1;
    fi

    #
    # install the app if we're in the web
    # service container
    #
    if ! installApplication; then
      pm-cli output:error "Could not install ProcessMaker" && exit 1;
    else
      pm-cli output:header "ProcessMaker successfully installed";
    fi

    #
    # install the ProcessMaker-specific enterprise packages, if desired
    #
    if [ "$INSTALL_ENTERPRISE_PACKAGES" = true ]; then
      if ! installEnterprisePackages; then
        pm-cli output:error "Could not install enterprise packages" && exit 1;
      else
        pm-cli output:header "ProcessMaker enterprise packages successfully installed";
      fi
    fi

    #
    # Mark as installed
    #
    touch storage/build/.installed;
  }

  #
  # ProcessMaker installation status
  #
  isInstalled() {
    if [ -f storage/build/.installed ]; then
      return 0;
    else
      return 1;
    fi
  }

  #
  # entrypoint function
  #
  entrypoint() {
    #
    # Source a few necessary env variables
    #
    sourceDockerEnv;

    #
    # If we don't find a linked .env file and this is
    # a web service, then we need to run the
    # app's artisan install command
    #
    if ! isInstalled; then
      if ! installProcessMaker | tee -a storage/build/install.log; then
        pm-cli output:error "Install failed. See storage/build/install.log for details." && exit 1;
      fi
    fi
  }

  entrypoint;
}
