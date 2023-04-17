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
  # ProcessMaker installation status
  #
  isProcessMakerInstalled() {
    if [ -f storage/build/.installed ]; then
      return 0
    else
      return 1
    fi
  }

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
  # Source a few necessary env variables
  #
  sourceDockerEnv

  #
  # Run the installation commands if not
  # installed
  #
  if ! isProcessMakerInstalled; then
    /usr/bin/install-processmaker && sleep 3
  fi

  #
  # Run the enterprise packages installation
  # commands if they're not already installed
  #
  if ! enterprisePackagesInstalled; then
    /usr/bin/install-enterprise-packages && sleep 3
  fi

  #
  # otherwise start the master supervisor
  # process
  #
  /usr/bin/supervisord -c /etc/supervisord.conf
}
