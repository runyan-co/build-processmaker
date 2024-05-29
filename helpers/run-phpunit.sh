#!/usr/bin/env bash

{
  docker compose exec -it queue bash -c "vendor/bin/phpunit -d 'memory_limit=2G' --testdox $*"
}
