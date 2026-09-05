#!/bin/sh
set -e

# Installs Pimcore, the Pimcore bundles, CoreShop and the demo data. Runs once: when the
# database already holds a Pimcore installation only the pending Doctrine migrations of
# Pimcore, its bundles and CoreShop are executed (image updates ship new migrations).
#
# Everything is read from the environment (Kubernetes secret / docker compose env_file):
#   DATABASE_HOST, DATABASE_PORT, DATABASE_NAME, DATABASE_USER, DATABASE_PASSWORD
#   PIMCORE_ENCRYPTION_SECRET        defuse key for pimcore.encryption.secret (config/config.yaml)
#   PIMCORE_INSTANCE_IDENTIFIER      Pimcore instance identifier
#   PIMCORE_PRODUCT_KEY              Pimcore product key (required at runtime, see README)
#   PIMCORE_INSTALL_ADMIN_USERNAME   admin user to create
#   PIMCORE_INSTALL_ADMIN_PASSWORD   password of that user
for var in PIMCORE_ENCRYPTION_SECRET PIMCORE_INSTANCE_IDENTIFIER PIMCORE_PRODUCT_KEY PIMCORE_INSTALL_ADMIN_USERNAME PIMCORE_INSTALL_ADMIN_PASSWORD; do
  if [ -z "$(printenv "$var")" ]; then
    echo "$var is not set" >&2
    exit 1
  fi
done

if php -r '$pdo = new PDO(sprintf("mysql:host=%s;port=%d;dbname=%s", getenv("DATABASE_HOST"), getenv("DATABASE_PORT") ?: 3306, getenv("DATABASE_NAME")), getenv("DATABASE_USER"), getenv("DATABASE_PASSWORD")); exit($pdo->query("SHOW TABLES LIKE \"users\"")->rowCount() > 0 ? 0 : 1);' 2>/dev/null; then
  echo "Pimcore is already installed, running pending database migrations"
  bin/console doctrine:migrations:migrate --no-interaction --allow-no-migration
  exit 0
fi

export PIMCORE_INSTALL_ENCRYPTION_SECRET="$PIMCORE_ENCRYPTION_SECRET"
export PIMCORE_INSTALL_INSTANCE_IDENTIFIER="$PIMCORE_INSTANCE_IDENTIFIER"
export PIMCORE_INSTALL_PRODUCT_KEY="$PIMCORE_PRODUCT_KEY"

echo "Install Pimcore"
vendor/bin/pimcore-install --skip-database-config --no-interaction
rm -rf var/config/system.yml

echo "Install Pimcore bundles, CoreShop and the demo data"
bin/console pimcore:bundle:install PimcoreSimpleBackendSearchBundle --no-post-change-commands
bin/console coreshop:install --no-interaction
bin/console pimcore:bundle:install PimcoreStudioBackendBundle --no-post-change-commands
bin/console pimcore:bundle:install PimcoreGenericDataIndexBundle --no-post-change-commands
bin/console pimcore:bundle:install PimcoreApplicationLoggerBundle --no-post-change-commands
bin/console generic-data-index:update:index -r
bin/console coreshop:install:demo --no-interaction
bin/console generic-data-index:update:index -r

# The cache built by the installer must not be reused by php-fpm; a failure to remove it
# (e.g. a bind mount that keeps directory entries) is not fatal.
rm -rf var/cache || true
