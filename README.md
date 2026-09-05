# CoreShop 5.1 Demo

Demo shop for [CoreShop](https://www.coreshop.com) 5.1 on Pimcore 12: the Pimcore skeleton plus
CoreShop with its demo data (`coreshop:install:demo`), the classic admin and Pimcore Studio.
The 2026 line lives in [coreshop/demo2026](https://github.com/coreshop/demo2026).

Live: https://demo5.coreshop.org (admin: `/admin`, Studio: `/pimcore-studio`).

## Run locally

Requirements: Docker. The images are built from `ghcr.io/cors-gmbh/pimcore-docker`.

```bash
cp .env .env.local            # adjust if needed
docker compose up -d
docker compose logs -f php    # wait for "Pimcore installed"; first start installs Pimcore, CoreShop and the demo data
```

Then open http://localhost (shop), http://localhost/admin (user `admin`, password from the
installer output) and http://localhost/pimcore-studio.

The install script `.docker/php/docker-install.sh` reads its secrets from the environment:

| Variable | Purpose |
|---|---|
| `PIMCORE_ENCRYPTION_SECRET` | defuse key for `pimcore.encryption.secret` (`vendor/bin/generate-defuse-key`) |
| `PIMCORE_INSTANCE_IDENTIFIER` | Pimcore instance identifier |
| `PIMCORE_PRODUCT_KEY` | Pimcore product key; **required**, Pimcore refuses to boot with an encryption secret but no registered product key (register the instance identifier at https://license.pimcore.com/register) |

Set them in `.env.local` for docker compose; in Kubernetes they come from the `pimcore` secret of
the manifest repository.

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
