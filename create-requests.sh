#!/usr/bin/env bash

set -e

export START=0
export PROCESS_ID=10
export NODE_ID=node_5
export COOKIE_STRING="device_id=7e762e3f3831168276714c57969dee695d39adb589ab69d3203288b5d5e89ebbcbf2a26f2dc4e4b411e70399ade797c83f828ca75b8e91e8458bd95b14c28db3; io=6PBKyuLn-rWC_98bAAAV; laravel_token=eyJpdiI6InkwYVBBeXp1V041aUh4UjFJTjZYeGc9PSIsInZhbHVlIjoiTmJnZGhiUFdNdjhaaG9NWkExdU1IUDZmdzVtcjRRZXljNHE5MFZIaXdneWJiblpsUW9QUmRFeFZ1cldzaGNleWpVdjMwcTNzeDNFZWovMUtoeEliaEtBbDhrUDYrM0VqR3dPRmliaFQyc09qZjBDWVpBK1Jmb1FORjNIdDhPWmZSZ1paR1k5Yms2ZG84QnZoSVdNMUdLOFVCUURnVHNPUWc1QlVDR09HcXlPdUZZaEdqRXZwMVBvUFlVUkFRTGdreVpST3NHLzMxeDJlYkUvNnJYZWZSRFZoSlp6U1F6OC9tVXh0K3I5cGRaYWpOOC83UjJXdVY2VFluMld4OEU5amZ6QThkS0ZRVDdwR2NoQ2g1aFhLVkpwd2VqQWhPcXl3dmk4b3NkTU1DZ2c2cDlSYmErRDZYNG0rU0p4RHZUMS8iLCJtYWMiOiJiYWNmNjUxMDE4OTQzOTIwNzk3YWFkNzA1MzE0ZjY4OTcyMWYxMDkzY2M5OWE4ZGJkOGMxZmRjOTJhOWQ5MjZjIiwidGFnIjoiIn0%3D; processmaker_session=eyJpdiI6ImNYcW5rMlNCNk9mR2VCdWpUanZOOHc9PSIsInZhbHVlIjoiaGJYVng0L0JIS1pKRUZCRnhwam5YUDNieFYvUEZURnJRRkFOU0l3d2hmU0ZTczBNS2U0Q1hKbG1YY1pKM3dXK2taVURnVHk1UERURlJobHc2M3JNYTl6VnM2QU8veUYzTXRNdzlwc0pUV1hobTIxWUhKQzhmZmdpZGxrMXpVTm8iLCJtYWMiOiI4ZTkzYjBkNzUzNTIwZDIwNWYwZjgwNzRlMDcwNmEyODhhZmVkMDZjZDQxYmZkODhiYTMzYTE1ZGEwYWIzN2ZjIiwidGFnIjoiIn0%3D"
export CSRF_TOKEN="4ft61ZuRWH9ngUMtKpomtF7j7Xf9oebakWcXKyCC"
export OUTPUT_FILE_NAME="$(php -r "echo uniqid().PHP_EOL; ?>")"

request() {
  curl "http://processmaker.test/api/1.0/process_events/$PROCESS_ID?event=$NODE_ID" \
    --show-error \
    --fail-early \
    --compressed \
    --insecure \
    --silent \
    -o "/tmp/$OUTPUT_FILE_NAME.log" \
    -X 'POST' \
    -H 'Accept: application/json, text/plain, */*' \
    -H 'Accept-Language: en,en-US;q=0.9' \
    -H 'Connection: keep-alive' \
    -H 'Content-Length: 0' \
    -H "Cookie: $COOKIE_STRING" \
    -H 'DNT: 1' \
    -H 'Origin: http://processmaker.test' \
    -H 'Referer: http://processmaker.test/requests' \
    -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/111.0.0.0 Safari/537.36' \
    -H "X-CSRF-TOKEN: $CSRF_TOKEN" \
    -H 'X-Requested-With: XMLHttpRequest'
}

if [ $START = 1 ]; then
  # Hit ctrl-c to enc the loop my guy
  until false; do
    request & request & request & request & request & wait && sleep 1;
  done
fi
