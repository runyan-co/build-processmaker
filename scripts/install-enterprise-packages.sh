#!/usr/bin/env bash

{
  #
  # ProcessMaker enterprise packages installation status
  #
  enterprisePackagesInstalled() {
    if [ -f storage/build/.packages-installed ]; then
      return 0
    else
      return 1
    fi
  }

  #
  # ProcessMaker installation status
  #
  isProcessMakerInstalled() {
    if [ -f storage/build/.installed ]; then
      return 0;
    else
      return 1;
    fi
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
          pm-cli output:header "Installing processmaker/$PACKAGE"

          # Use composer to require the package
          # we want to install
          composer require "processmaker/$PACKAGE" --no-ansi --no-plugins --no-interaction

          # Run the related artisan install command
          # the package provides
          php artisan "$PACKAGE:install" --no-ansi --no-interaction

          # Publish any assets or files the package provides
          php artisan vendor:publish --tag="$PACKAGE" --no-ansi --no-interaction

          # Add the installed package to our
          # build dotfile for safekeeping
          echo "$PACKAGE" >>"$PACKAGES_DOTFILE"
        }
      done

      composer dumpautoload -o --no-ansi --no-interaction
      pm-cli output:header "Enterprise packages installed"

    else
      pm-cli output:header "Enterprise packages already installed"
    fi
  }

  #
  # install the ProcessMaker-specific enterprise packages, if desired
  #
  if isProcessMakerInstalled; then
    if ! enterprisePackagesInstalled; then
      php artisan horizon:pause --no-interaction --no-ansi
      if installEnterprisePackages; then
        pm-cli output:header "ProcessMaker enterprise packages successfully installed"
        touch storage/build/.packages-installed
      else
        php artisan horizon:continue --no-interaction --no-ansi
        pm-cli output:error "Could not install enterprise packages" && exit 1
      fi
      php artisan horizon:pause --no-interaction --no-ansi
    else
      pm-cli output:header "ProcessMaker enterprise packages already installed"
    fi
  else
    pm-cli output:header "ProcessMaker must be installed before installing enterprise packages"
  fi
}
