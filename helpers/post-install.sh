#!/bin/bash

{
  docker compose exec -it artisan php artisan package-pm-blocks:sync-pm-blocks --no-interaction
  docker compose exec -it artisan php artisan processmaker:sync-default-templates --no-interaction
  docker compose exec -it artisan php artisan processmaker:sync-guided-templates --no-interaction
  docker compose exec -it artisan php artisan optimize:clear --no-interaction
  docker compose exec -it artisan php artisan upgrade --no-interaction
  docker compose exec -it artisan php artisan config:cache --no-interaction
  docker compose exec -it artisan php artisan processmaker:regenerate-css --no-interaction

  echo ""
  echo "Removing installer container..."
  echo ""
  docker compose rm installer --force

  echo ""
  echo "Done!"
  echo ""
}
