#!/usr/bin/env bash

{
  #
  # create a loop using the sleep command to
  # ]keep the container running without using
  # substantial cpu resources
  #
  await() {
    sleep 60
    await
  }

  #
  # await connections from host
  #
  await
}
