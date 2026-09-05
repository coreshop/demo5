#!/bin/sh
set -e

# First start of the local docker compose stack (service "install" in docker-compose.yml):
# installs the composer dependencies when vendor/ is missing, waits for the database and runs
# the install script once. The php, php-debug and supervisord containers start after this
# script has finished successfully.
cd /var/www/html

export PIMCORE_INSTALL_ADMIN_USERNAME="${PIMCORE_INSTALL_ADMIN_USERNAME:-admin}"
export PIMCORE_INSTALL_ADMIN_PASSWORD="${PIMCORE_INSTALL_ADMIN_PASSWORD:-coreshop}"

for var in PIMCORE_ENCRYPTION_SECRET PIMCORE_INSTANCE_IDENTIFIER PIMCORE_PRODUCT_KEY; do
  if [ -z "$(printenv "$var")" ]; then
    echo "$var is not set: copy .env to .env.local and fill in the Pimcore registration values (see README)" >&2
    exit 1
  fi
done

if [ ! -f vendor/autoload.php ]; then
  echo "Installing composer dependencies"
  composer install --no-interaction --no-progress --no-scripts
fi

mkdir -p var/cache var/log public/var

/usr/local/bin/wait_db
until curl -sf -o /dev/null http://os:9200; do echo "Waiting for OpenSearch to be ready..."; sleep 2; done
sh .docker/php/docker-install.sh

echo "CoreShop demo installed: https://coreshop5-demo.localhost (admin: $PIMCORE_INSTALL_ADMIN_USERNAME)"
