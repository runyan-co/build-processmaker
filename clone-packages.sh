#!/usr/bin/env bash

{
  set -e
  source .env

  # TODO
  jq -r '.extra.processmaker.enterprise | to_entries[] | .key + ":" + (.value|tostring)' "$PM_APP_SOURCE/composer.json" | while IFS=: read -r package version; do
      {
        cd "$PM_COMPOSER_PACKAGES_SOURCE_PATH"
        git clone "https://github.com/ProcessMaker/$package"
      } &
  done
  wait
  echo "Done"
}
