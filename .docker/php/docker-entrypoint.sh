#!/bin/sh
set -e

# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
  set -- php-fpm "$@"
fi

/usr/local/bin/wait_db
/usr/local/bin/install

# The readiness probe (/usr/local/bin/health) only reports ready once the install has finished,
# so a rolling restart keeps the old pod serving until the new one is fully set up.
touch /tmp/.pimcore_installed

exec docker-php-entrypoint "$@"
