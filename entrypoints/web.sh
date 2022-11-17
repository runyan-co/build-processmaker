#!/usr/bin/env bash

{
  if [ ! -f "$PM_DIRECTORY/storage/keys/.env" ]; then
      echo "Queue .env file not found (env not ready)..." && sleep 3 && exit 0
  elif [ ! -f "$PM_DIRECTORY/.env" ]; then
      cp "$PM_DIRECTORY/storage/keys/.env" .
  fi

  if [ -f "$PM_DIRECTORY/storage/framework/maintenance.php" ]; then
    echo "ProcessMaker in maintenance mode..." && sleep 3 && exit 0
  fi

  composer update --optimize-autoloader --no-ansi --no-suggest

  bash -c 'NPX_EXECUTABLE="$(which npx)" supervisord --nodaemon'
}
