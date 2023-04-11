#!/usr/bin/env bash

{
  #
  # restore public dir
  #
  restorePublicDirectory() {
    echo "Restoring: $PM_DIR/public" && \
    git restore "$PM_DIR/public"
  }

  #
  # restore app-specific storage dir
  #
  restoreAppStorage() {
    echo "Restoring: $PM_DIR/storage/app" && \
    git restore "$PM_DIR/storage/app"
  }

  #
  # empty the ./vendor directory
  #
  emptyVendorDir() {
    if [ -d "$PM_DIR/vendor" ]; then
      rm -rf "$PM_DIR/vendor"
    fi
  }

  #
  # empty the ./node_modules directory
  #
  emptyNodeModulesDir() {
    if [ -d "$PM_DIR/node_modules" ]; then
      rm -rf "$PM_DIR/node_modules"
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
    pm-cli output:header "Setting up environment"

    if [ ! -f "$ENV_REALPATH" ]; then
      echo "Copying env setup file to build folder" && \
      cp "$PM_SETUP_DIR/.env.example" "$ENV_REALPATH"
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
      echo "APP_URL=${PM_APP_URL_WITH_PORT}"
      echo "BROADCASTER_HOST=http://${PM_DOMAIN}:${PM_BROADCASTER_PORT}"
      echo "SESSION_DOMAIN=${PM_DOMAIN}"
      echo "HOME=${PM_DIR}"
      echo "NODE_BIN_PATH=$(which node)"
      echo "PROCESSMAKER_SCRIPTS_DOCKER=$(which docker)"
      echo "PROCESSMAKER_SCRIPTS_HOME=${PM_DIR}/storage/app/scripts"
      echo "DB_HOST=${DB_HOST}"
      echo "DB_PORT=${DB_PORT}"
      echo "DB_HOSTNAME=${DB_HOST}"
      echo "DB_NAME=${DB_NAME}"
      echo "DB_USERNAME=${DB_USERNAME}"
      echo "DB_PASSWORD=${DB_PASSWORD}"
      echo "DATA_DB_HOST=${DB_HOST}"
      echo "DATA_DB_USERNAME=${DB_USERNAME}"
      echo "DATA_DB_PASSWORD=${DB_PASSWORD}"
      echo "DATA_DB_PORT=${DB_PORT}"
      echo "DATA_DB_NAME=${DB_NAME}"
    } >>"$ENV_REALPATH"

    if [ -f "$PM_DIR/.env" ]; then
      echo "Removing default .env file" && rm -f "$PM_DIR/.env"
    fi

    echo "Copying env file to app directory" && cp "$ENV_REALPATH" "$PM_DIR"
  }

  #
  # Install app's composer dependencies
  #
  installComposerDeps() {
    pm-cli output:header "Installing composer dependencies"

    composer install \
      --profile \
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
  npmInstallAndBuild() {
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
    # Install composer dependencies
    #
    if ! installComposerDeps; then
      pm-cli output:error "Error while installing composer dependencies" && exit 1
    fi

    #
    # Install npm dependencies and run build
    #
    if ! npmInstallAndBuild; then
      pm-cli output:error "Error while installing npm dependencies or building assets" && exit 1
    fi

    #
    # Run the remaining artisan commands to
    # finish the base installation
    #
    php artisan key:generate --no-interaction --no-ansi
    php artisan package:discover --no-interaction --no-ansi && sleep 1
    php artisan horizon:publish --no-interaction --no-ansi && sleep 1
    php artisan migrate:fresh --force --no-interaction --no-ansi && sleep 1
    php artisan db:seed --force --no-interaction --no-ansi && sleep 1
    php artisan passport:install --no-interaction --no-ansi && sleep 1
    php artisan storage:link --no-interaction --no-ansi && sleep 1
    php artisan telescope:publish --force --no-interaction --no-ansi && sleep 1
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
  # restore directories which were
  # emptied when persisted volumes
  # were mounted
  #
  restoreDirectories() {
    restorePublicDirectory
    restoreAppStorage
    emptyVendorDir
    emptyNodeModulesDir
  }

  #
  # Install steps
  #
  installProcessMaker() {
    set -e

    #
    # Wait for MySQL to come online
    #
    awaitMysql

    #
    # commands to restore directories
    # replaced by persisted volumes
    # when initialized
    #
    restoreDirectories

    #
    # setup the environment
    #
    if ! setupEnvironment; then
      pm-cli output:error "Could not setup environment" && exit 1
    fi

    #
    # install the app if we're in the web
    # service container
    #
    if ! installApplication; then
      pm-cli output:error "Could not install ProcessMaker" && exit 1
    fi

    touch storage/build/.installed
    pm-cli output:header "ProcessMaker successfully installed"
  }

  #
  # run the install and duplicate the
  # output to a log file
  #
  if ! installProcessMaker | tee -a storage/build/install.log; then
    pm-cli output:error "Install failed. See storage/build/install.log for details." && exit 1;
  fi
}
