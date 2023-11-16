#!/usr/bin/env bash

{
  set -e
  source ./.env

  sendHttpRequest() {
    true
  }

  while true; do
    for i in {0..32}; do
      { echo "$i" && sendHttpRequest >/dev/null; } &
    done
    wait
  done
}
