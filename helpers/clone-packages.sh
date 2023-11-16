#!/usr/bin/env bash

# Fail on any error and on any failed pipeline
set -eox pipefail

# Load the environment variables if .env file exists
if [[ -f ".env" ]]; then
  source .env
else
  echo ".env file not found."
  exit 1
fi

# Read and process packages
jq -r '.extra.processmaker.enterprise | to_entries[] | .key + ":" + (.value|tostring)' "$PM_APP_SOURCE/composer.json" | while IFS=: read -r package version; do
  {
      # Make sure the source path is available
      if [[ -d "$PM_COMPOSER_PACKAGES_SOURCE_PATH" ]]; then
        cd "$PM_COMPOSER_PACKAGES_SOURCE_PATH"

        # Remove existing directory if it exists
        if [[ -d "$package" ]]; then
          echo "$package: Deleting expired source directory..."
          rm -rf "$package"
        fi

        # Clone the package repository
        echo "$package: Cloning package..."
        git clone "https://github.com/ProcessMaker/$package" &
      else
        echo "Directory $PM_COMPOSER_PACKAGES_SOURCE_PATH does not exist."
        exit 1
      fi
  }
done

# Wait for all background processes to finish
wait
echo "Done"
