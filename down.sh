#!/usr/bin/env bash

#
# graceful take down of services,
#
{
  set -e
  docker compose down
}
