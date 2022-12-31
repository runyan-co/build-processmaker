#!/usr/bin/env bash

{
  #
  # create a loop using the sleep command to
  # ]keep the container running without using
  # substantial cpu resources
  #
  await() {
    while true; do
      sleep 60
    done;
  }

  #
  # await connections from host
  #
  await
}
