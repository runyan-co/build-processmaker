#!/usr/bin/env bash

{
  source ./.env

  randomString() {
    php ./random-string.php;
  }

  getBpmnProcessId() {
    php -r "echo (random_int(0, 1024) > random_int(0, 1024) ? 12 : 13).PHP_EOL;"
  }

  getRandomBool() {
    php -r "echo (random_int(0, 1024) > random_int(0, 1024) ? 1 : 0).PHP_EOL;"
  }

  startStandardProcess() {
    timeout 5 curl 'http://processmaker.test/api/1.0/process_events/'"$(getBpmnProcessId)"'?event=node_1' \
        -X 'POST' \
        -H 'Accept: application/json, text/plain, */*' \
        -H 'Accept-Language: en,en-US;q=0.9' \
        -H 'Cache-Control: no-cache' \
        -H 'Connection: keep-alive' \
        -H 'Content-Length: 0' \
        -H 'Cookie: device_id=b0fd5a706e52b380f4d05fa72808aedd445bea17c25cb798b446f48c7c46bcac16d5920393494fcbd541520b491c6f9773c7414dca672a7b8819ba7c3dc844ce; laravel_token=eyJpdiI6Im5vQmxud1c0ZExnQ2JMRzl0MlFRdFE9PSIsInZhbHVlIjoiY2szdjdNUjRTTkJma3dINUJ6L1A4SEFUQVlzZnZhTllHOTFVWnhKeElsTlZHMkpCM0V0dUxnVjlMUmxlMWhaL24vR2swVmxUdzFaRFpxdGlRRGc4SkordDBZNVYzSGFheTRHWjNJTjYxaExsRU5NNmFrTmZqREJKR0ZZaGxPUDFIUkR0Um5BbURGMmVZdThYNWw3aXRzd0ZwVXg2UHZheGpBLzluNnBxVmhtQk1LRzJRcmJlRTZHVDRjaFFJQ2ZFTUgvZ3NCZmF3NExJZEM1MFlxSnpTdGNXZnlLbTVZeVVSTnYwMklMZ3l4b3hUY1FJVlRrSXN0ZFlpZzlxMVJ4R0Zic0pvQjI0MzFLZW4xMkl4bFpac1Y4WVFlK3hvS0wyMUZTKzBsMXBnN1NzajNNMW8vNjFhWjdvWWZwOUEwL3YiLCJtYWMiOiIzMDE2OTczZTM2NmM2MWVhN2Y4YTFhOTcwMDlkNGJjMWNlZTZjNzM1MTU3YjA1MDU2ZmZhYTExZDQwNDFhMDIwIiwidGFnIjoiIn0%3D; processmaker_session=eyJpdiI6Ik1SY1EvT3QxRXdReDVRaThTWE5pbFE9PSIsInZhbHVlIjoidkREbHMwNmt5K0NDRGdnY3RKd251eGVGWXBJV0UwVWxJNDhwVC9QdGNmZFN0Q1B5KzhXM2JIY2U3SW1UeUFpeTFsODhPS05MZ3k5R3oxY3pmcW9tV044Q2Q3YVY3Kzc0ZDVZQlFzVmhGaHpFUzRER3IyS0d0VW9FRHdNekRQZEgiLCJtYWMiOiIwMTE0NDg3YjM2YzRlNWY2MzM4MTZhNGY1ZTljZDMzM2Q5NTBiYTBjYTY1NTE5YzI3YzZjYjk5YTZmYTljNzE3IiwidGFnIjoiIn0%3D' \
        -H 'DNT: 1' \
        -H 'Origin: http://processmaker.test' \
        -H 'Pragma: no-cache' \
        -H 'Referer: http://processmaker.test/requests' \
        -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36' \
        -H 'X-CSRF-TOKEN: Kbf9njME8p8hNZr0OpHojFyMoMjYA2uA1G3e0eSH' \
        -H 'X-Requested-With: XMLHttpRequest' \
      --compressed \
      --insecure \
      --silent >/dev/null
  }

  startWebEntryRequest() {
    timeout 5 curl 'http://processmaker.test/api/1.0/webentry/processes/14/web_entries/node_10/start?token=659d9997753c8' \
      -H 'Accept: application/json, text/plain, */*' \
      -H 'Accept-Language: en' \
      -H 'Cache-Control: no-cache' \
      -H 'Connection: keep-alive' \
      -H 'Content-Type: application/json' \
      -H 'Cookie: laravel_token=eyJpdiI6InBvaTN4RXk4MEhQdFNNVStIRVFKaGc9PSIsInZhbHVlIjoiVmgyejlHVEJNWndleEJMSE9OWmhUQjgrVFFsc2FuOEZWNkt6NWtsckxQTW1yRzhSeUN0YWpiUzNkU1FHSFZBL21GL202WWhmSGNGYW9VMmpnOGdEYnRjZXk0OFJReEwxcXJwbWU2NW5mNkQ1bFdHM1F0YXBzdFBVbGdIWkdLK3Fxa3NPTVlWemNCV1JTZy9SUDRxdGdtTDYyNjB3T0hCUlhwL0RXdXRhb2VLYjUxUTlKdFNiY0VPbmRtQlZZbWxGTXhLajI0WkdIUWNKNUtiYmtSQkp5emZDMEFHc2xSWER4cmZwd2JOL2ZjeVhDYlF5TVUvdER2UDZjRitWQ1V3ZkZkQUZiVW1hSHB6c0k1ZTQ3MEx1ejVCYkZtQnNQRkF4VHpKMktTUHRmdGxNbTl1UGhTdzNOZTJQaWNveUF5eDQiLCJtYWMiOiI0ZmZhN2JkM2Q1MTE4ZGE3NzhjOGRmMjNmNWFhYTdkMjdhNDQzOTI1ZjljZGJlNDVkMjhlYTc0ZDI4NWExMDYwIiwidGFnIjoiIn0%3D; device_id=90f72b7c152d817c850a7b844561756ddc8d0085f896077c3bd117dd86c0b9107008f312f2dbf4d62f597a0dc171049c9369eecab557c22591fd4fba6f7e7c86; processmaker_session=eyJpdiI6IlU3NFdhd0xydkdiRU1ENVJha05xOXc9PSIsInZhbHVlIjoiZ2x0V1NxeUlXS0hDbU54SXl3WXlKa3dBem5qUXRFRmdHdUwvSXhQemhhQlVmOG5mdDZmUWNNUkoycmE5bFliakFHYkI5Z2RGOVBMR1Y4N0Uzd0NiMU1NZ29wOEtHRDJXY05TenF6UWljQkxIY1ZlTExtU2U0dWh6ZU0vUDZDTmwiLCJtYWMiOiJiMWE3MTA5YzgyZWEyMmU0ZjZlMzU4YzM2YzU0N2U1NzBhNzYxZTQ2NTgzMGZhNDdkMjMyNzE5MmMyNzFjZGEzIiwidGFnIjoiIn0%3D' \
      -H 'DNT: 1' \
      -H 'Origin: http://processmaker.test' \
      -H 'Pragma: no-cache' \
      -H 'Referer: http://processmaker.test/webentry/14/node_10' \
      -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36' \
      -H 'X-CSRF-TOKEN: XXETHr8p07kmWUWvVhAk7yuA8JTZoJ3a5f59wxeo' \
      -H 'X-Requested-With: XMLHttpRequest' \
      --data-raw '{"data":{"_user":{"id":2,"uuid":"9b0cd18a-d548-48d4-b305-7e5dc466e2af","email":"anonymous-pm4-user@processmaker.com","firstname":"Anonymous","lastname":"User","username":"_pm4_anon_user","status":"ACTIVE","address":null,"city":null,"state":null,"postal":null,"country":null,"phone":null,"fax":null,"cell":null,"title":null,"birthdate":null,"timezone":"America/Los_Angeles","datetime_format":"m/d/Y H:i","language":"en","meta":null,"is_administrator":false,"is_system":1,"expires_at":null,"loggedin_at":null,"active_at":null,"created_at":"2024-01-09T09:46:14+00:00","updated_at":"2024-01-09T09:46:14+00:00","deleted_at":null,"delegation_user_id":null,"manager_id":null,"schedule":null,"force_change_password":0,"avatar":null,"fullname":"Anonymous User"},"subject":"sdf","description":"sdfgsfdgfdg","requesterName":"asdf","email":"asdf@asdf.com"},"query":{},"referer":""}' \
      --compressed \
      --insecure \
      --silent >/dev/null
  }

  sendHttpRequest() {
    if [ "$(getRandomBool)" = "0" ]; then
      startWebEntryRequest
    else
      startStandardProcess
    fi

    echo "Done: $2"
    exit 0
  }

  while true; do
    for i in {0..16}; do
      { echo "Starting $i" && sendHttpRequest "$(randomString)" "$i"; } &
    done
    wait
    sleep 1
  done
}
