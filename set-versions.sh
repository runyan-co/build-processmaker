#!/usr/bin/env bash

{
  set -e
  source .env

  # TODO
  jq -r '.extra.processmaker.enterprise | to_entries[] | .key + ":" + (.value|tostring)' "$PM_APP_SOURCE/composer.json" | while IFS=: read -r package version; do
      echo "Package Name: $package"
      echo "Version: $version"
      echo ""
  done
}
