#!/usr/bin/env bash

{
  source ./.env

  export URL=""
  export COOKIE=""

  randomString() {
    php ./random-string.php;
  }

  sendHttpRequest() {
    timeout 5 curl "$URL" \
      -H 'Accept: application/json, text/plain, */*' \
      -H 'Accept-Language: en' \
      -H 'Connection: keep-alive' \
      -H 'Content-Type: application/json' \
      -H 'Cookie: ' \
      -H 'DNT: 1' \
      -H 'Origin: http://processmaker.test' \
      -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36' \
      -H 'X-Requested-With: XMLHttpRequest' \
      --data-raw '{}' \
      --compressed \
      --insecure \
      --silent >/dev/null && echo "Done: $2" && exit 0
  }

  while true; do
    for i in {0..16}; do
      { echo "Starting $i" && sendHttpRequest "$(randomString)" "$i"; } &
    done
    wait
    sleep 1
  done
}
