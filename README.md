# CoreShop 5.1 Demo

Demo shop for [CoreShop](https://www.coreshop.com) 5.1 on Pimcore 12: the Pimcore skeleton plus
CoreShop with its demo data (`coreshop:install:demo`), the classic admin and Pimcore Studio.
The 2026 line lives in [coreshop/demo2026](https://github.com/coreshop/demo2026).

Live: https://demo5.coreshop.org (admin: `/admin`, Studio: `/pimcore-studio`).

## Run locally

Requirements: Docker with Compose v2.24 or newer and the running cors dev traefik (network
`cors_dev`, host names `*.localhost`). The images come from `ghcr.io/cors-gmbh/pimcore-docker`
(PHP 8.3); the repository is bind-mounted, nothing is built locally.

```bash
cp .env .env.local
# fill in PIMCORE_ENCRYPTION_SECRET, PIMCORE_INSTANCE_IDENTIFIER and PIMCORE_PRODUCT_KEY in .env.local
docker compose up -d
docker compose logs -f install   # wait for "CoreShop demo installed"
```

The first start runs the one-shot `install` service (`.docker/php/docker-dev-install.sh`): it
installs the composer dependencies when `vendor/` is missing, waits for the database and runs
`.docker/php/docker-install.sh`, which installs Pimcore, the Pimcore bundles, CoreShop and the demo
data. The php, php-debug and supervisord containers start after it has finished. Later starts detect
the existing installation and skip it; `docker compose down -v` gives you a fresh shop.

| URL | Login |
|---|---|
| https://coreshop5-demo.localhost | shop |
| https://coreshop5-demo.localhost/admin | `admin` / `coreshop` (ExtJS admin) |
| https://coreshop5-demo.localhost/pimcore-studio | `admin` / `coreshop` (Studio) |

Environment (`.env` plus the optional `.env.local`, both passed to every PHP container; the local stack
runs `APP_ENV=dev`):

| Variable | Purpose |
|---|---|
| `PIMCORE_ENCRYPTION_SECRET` | defuse key for `pimcore.encryption.secret` (`vendor/bin/generate-defuse-key`), **required** |
| `PIMCORE_INSTANCE_IDENTIFIER` | Pimcore instance identifier, **required** |
| `PIMCORE_PRODUCT_KEY` | Pimcore product key, **required**: Pimcore refuses to boot with an encryption secret but no registered product key (register the instance identifier at https://license.pimcore.com/register) |
| `PIMCORE_INSTALL_ADMIN_USERNAME`, `PIMCORE_INSTALL_ADMIN_PASSWORD` | admin user created by the installer, default `admin` / `coreshop` |

In Kubernetes the same variables come from the `pimcore` secret of the manifest repository, and the
image entrypoint runs the same install script.

## CI/CD

| Workflow | Trigger | What it does |
|---|---|---|
| `build.yml` | push to `main`, PR | builds the images `php-alpine-fpm`, `php-alpine-supervisord`, `nginx`; on `main` pushes them to `ghcr.io/coreshop/demo5/{php-fpm,php-supervisord,nginx}` tagged `main-<sha>` and `latest` and bumps the tags in [coreshop/demo5-manifest](https://github.com/coreshop/demo5-manifest) |
| `static.yml` | push, PR | `composer validate`, YAML/Twig/container lint, phpstan level 1 on `src/` |
| `composer-update.yml` | daily 03:00, manual | `composer update` as a pull request |

Required secrets:

- `GITHUB_TOKEN` (automatic, `packages: write`): pushes the images to the GitHub Container Registry
- `GH_APP_ID`, `GH_APP_PRIVATE_KEY` (org secrets, already present): the coreshop GitHub App mints the token
  for the manifest push; the app must be installed on `coreshop/demo5-manifest` with `contents: write`

No `COMPOSER_AUTH` is needed, every dependency comes from packagist.org.

The container packages are created private by GitHub on the first push; switch
`ghcr.io/coreshop/demo5/*` to public once in the GitHub UI (Packages → package → settings), or keep them
private and let the cluster pull with the `ghcr-pull` secret described in the manifest repository.

Deployment itself happens from the manifest repository (Helm chart, synced by the cluster).

## License

CoreShop is licensed under the CoreShop Commercial License (CCL); the demo project code is MIT-style
skeleton code from Pimcore.
