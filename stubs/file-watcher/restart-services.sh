#!/usr/bin/env bash

{
  containerIds() {
    docker container ps --filter status=running | grep 'cron\|queue\|php-fpm' | awk '{ print $1; }';
  }

  echo "Restarting cron, php-fpm, and queue containers"

  docker container restart --time 0 $(containerIds) && echo "Containers restarted"
}
