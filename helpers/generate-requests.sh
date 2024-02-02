#!/usr/bin/env bash

{
  source ./.env

  randomString() {
    php -r '$length = \random_int(16, 256); $characters = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"; $charactersLength = strlen($characters); $randomString = ""; for ($i = 0; $i < $length; $i++) { $randomString .= $characters[\random_int(0, $charactersLength - 1)]; } echo $randomString.PHP_EOL;'
  }

  getBpmnProcessId() {
    php -r "echo (random_int(0, 1024) > random_int(0, 1024) ? 12 : 13).PHP_EOL;"
  }

  getRandomBool() {
    php -r "echo (random_int(0, 1024) > random_int(0, 1024) ? 1 : 0).PHP_EOL;"
  }

  startStandardProcess() {
    timeout 5 curl 'http://processmaker.test/api/1.0/process_events/33?event=node_300' \
                -X 'POST' \
                -H 'Accept: application/json, text/plain, */*' \
                -H 'Accept-Language: en,en-US;q=0.9' \
                -H 'Cache-Control: no-cache' \
                -H 'Connection: keep-alive' \
                -H 'Content-Length: 0' \
                -H 'Cookie: isMobile=false; device_id=a88e4da41286e44352ecff50b9b469d08e4689b087bdbc88d720ba5ffa9997a1405441fe996409d2891560cf85a6554350f979dd9f9b3969751e80191d74eade; _ga=GA1.1.465403487.1706680565; _ga_JKZEHMJBMH=GS1.1.1706680564.1.1.1706680595.0.0.0; laravel_token=eyJpdiI6InIwTm5mV0dzRWpjR21IMzlLd0h0bEE9PSIsInZhbHVlIjoibGExUzl5NThsVmdVWUlmc2FnOWZpNE5ZQ09ONi8zWVRqNDRRVUhQTFRHclA0TWcra3RkQkdYVUtHUytDNkpvMk5pMDdLNGpFdENLWTIvcERCSGtIVVMzMFNndjEzbS9GRVQ3UW5GN1YxMmordnlzdDRwNWMrRXdhV090RkF0QnM0M3NwRDY2dmduSGxudjlCbzNhWFdmOGhGZWJlcTNPcGVHcXp6anV2VFhJVDE2enY4K28xRGFRbVVadm9BNWxDcUNZSVBVQlQ3QW83VFRSS1FiNHV1ZlNoRFFyR2hMK04yMFE2a1R5U0NSSitabEZNa3hRTDZjbjlqa3VLS3BYeVZRZVdLc2VwUFhzTmo4WTRRZmFOQ3B4ZXh6TVNCakh3Qzl2cUJxZHU2SnVrQ2s1NGZabWR1OUorSk9LSjJmUTQiLCJtYWMiOiJjNjI1Mzg5YjA1MjY1YjdmNWI3NGIzYzY3Y2ZhZGU2OTA3OWNhYjlmMTIwMGJjMjlhNzEwYTkyNzI1Yzg1OGFmIiwidGFnIjoiIn0%3D; processmaker_session=eyJpdiI6IkM4bE9ldDB1VkpIbDJKZGE0aWpUVVE9PSIsInZhbHVlIjoidVkrRzFEeFpjWWNpWHVnUUhJTjdTNHV1bktDRnVFNFlMbEJyZHMrUkQwWWRzRXBnRWFMb01ONGxxUk4wcS9yY3FZekRvTG9uWk8va3VVSlVYbmNzbDZhREkyc3lYNXR5NGVwb3JldnZDeFA2Qm1XRGdXdlZsTkxpY3hjL2FYTXkiLCJtYWMiOiI1YjkwNGUxMGM1ZTgzMTg2MWIwMDJkZmUyOTM5ZjNhMDVhOWFmNmFjNjljNDRiMzM5MDk0Mjc5Y2RiYjFhZDYxIiwidGFnIjoiIn0%3D' \
                -H 'DNT: 1' \
                -H 'Origin: http://processmaker.test' \
                -H 'Pragma: no-cache' \
                -H 'Referer: http://processmaker.test/processes' \
                -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36' \
                -H 'X-CSRF-TOKEN: r7mB79NOqwtDAC86wvK5wFpmJUdym9kLSAaQpGBa' \
                -H 'X-Requested-With: XMLHttpRequest' \
                --compressed \
                --insecure \
                --silent >/dev/null
  }

  sendHttpRequest() {
    startStandardProcess
    echo "Done: $2"
    exit 0
  }

  while true; do
    for i in {0..32}; do
      { echo "Starting $i" && sendHttpRequest "$(randomString)" "$i"; } &
    done
    wait
    sleep 1
  done
}
