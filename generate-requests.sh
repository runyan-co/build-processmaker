#!/usr/bin/env bash

{
  set -e
  source ./.env

  sendHttpRequest() {
    curl 'http://processmaker.test/api/1.0/process_events/11?event=node_154' \
      -X 'POST' \
      -H 'Accept: application/json, text/plain, */*' \
      -H 'Accept-Language: en,en-US;q=0.9' \
      -H 'Connection: keep-alive' \
      -H 'Content-Length: 0' \
      -H 'Cookie: io=16RnADF1KP3YYnZ7AAAA; device_id=a2be255ba4698c51f7cb2bcf82eaee30d5d4b3b24e5b0b11246284918c746717a3386da5a82bd0353dca0bd439fd75dd21c7f792ce41cda685720fe1830cf758; laravel_token=eyJpdiI6ImpmNjJyYm9CR2hZMktBbTgvcUQ1NHc9PSIsInZhbHVlIjoiQ1pRS2JoRVZNdjVhTlFGUU5aT05TNS9lRXJwRmVFN29lREdla2NHcGljTldwaFRibUtHdlNudTU2a2M5ZGtmQmdWcW45Sm1zWk5HNFhQaTMvYXRsR2JHR3E2Q1dodFhFTkRqVExSRnJncUJWRFhub1J1Y0RucWo0Z2x2YTFaVU9FYVZXNGtFS1NHTlpIZzRHSmhNWGZETDdqckxkMWpOMkQzUGFZekNuT3o0bTVJWXl1a2ZmV3o2c0RMN1kyQTRZNkNRYUd6NnpyS2QrbHVaZXJHbUNIS2NrT1B3cVlDMkJOMnQ2aUc5NlpLTzZ0dWp2eFZZZHJLejFZcVR6NFRjNE55SWhNeVdxNmRIa0Jpb0dybHRWUHZkb3NwOEU2ZzVPUzNOS1JqMzBiNTdHUUJaNk4vZGRIakNuS2l6Q2FTRFciLCJtYWMiOiJhYzE1MGI1NTBjZGZiNTExNzM0NWM3OWY3MDRhOGQ4YWQ3MDFkNmUyZTA1OGJjYjczYTBiMzBjYmY1Zjk5YjdlIiwidGFnIjoiIn0%3D; processmaker_session=eyJpdiI6Ik5qdGxlcS8yaGpIMzhTNW5CQTd6Y0E9PSIsInZhbHVlIjoiWTFOYm5NaWNQRTNmYmVMaWxzUFVEbE1mUGs0ek4wMkszaWtESVNHMCs2T3ZCbVlHaCtqZytVNmt2MUlhNHlFbGYxUEpoM2pTMzJMT1VQUk5FY0t6SWM3NjhQKzQrNHlFR2RGREEvRHFJUkI4TFlnc2p0VTBFYXJwOEg4ckwwZUIiLCJtYWMiOiI4NzA3MmFkZTFhOTA0YzA2MmIyYWEyZTQ1Y2ZiZDc5MTBhMWI3NjFkZGRlOWJhZWQ2YzRmMDczYmJiZmRmZjVlIiwidGFnIjoiIn0%3D' \
      -H 'DNT: 1' \
      -H 'Origin: http://processmaker.test' \
      -H 'Referer: http://processmaker.test/processes' \
      -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Safari/537.36' \
      -H 'X-CSRF-TOKEN: SN1A38grl3eUpzMr8m5z74vS2Rztx6GZLmSzOvgX' \
      -H 'X-Requested-With: XMLHttpRequest' \
      --compressed \
      --insecure \
      --silent
  }

  while true; do
    for i in {0..128}; do
      { echo "$i" && sendHttpRequest >/dev/null; } &
    done
    wait
  done
}
