#!/bin/sh
set -e

# Ready = the install script has finished (marker set by the entrypoint) and php-fpm answers /ping.
if [ ! -f /tmp/.pimcore_installed ]; then
  echo "install not finished yet" >&2
  exit 1
fi

export SCRIPT_NAME=/ping
export SCRIPT_FILENAME=/ping
export REQUEST_METHOD=GET

if cgi-fcgi -bind -connect 127.0.0.1:9000; then
  exit 0
fi

exit 1
