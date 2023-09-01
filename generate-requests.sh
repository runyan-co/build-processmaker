#!/usr/bin/env bash

{
  set -e
  source ./.env

  # TODO
  sendHttpRequest() {
    true
  }

  while true; do
    for i in {0..128}; do
      { echo "$i" && sendHttpRequest >/dev/null; } &
    done
    wait
  done
}
