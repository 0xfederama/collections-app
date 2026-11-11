# Running the app

Three environments, one command each. Every command takes any `docker compose` subcommand (`ps`, `logs -f api`,
`restart web`, `exec db psql -U collection`, ...) plus a few extras, and `--help` prints its usage.

| | `./deploy/dev` | `./deploy/test` | `./deploy/prod` |
|---|---|---|---|
| For | Automated checks: unit, integration, e2e, smoke (agents) | Your manual testing | The real app (Raspberry Pi, LAN) |
| Web | http://localhost:5183 (Vite, hot reload) | http://localhost:5173 (Vite, hot reload) | `WEB_BIND:WEB_PORT` (Pi: LAN IP, port 80; Caddy, built SPA) |
| API | http://localhost:8090 | http://localhost:8080 | not published (behind web) |
| Data | Disposable: `--fresh` wipes it | Persistent, never touched by agents | Persistent, with backups |
| Settings | `local/dev.env` | `local/test.env` | `server/.env` (from `server/.env.example`) |
| Secrets | `backend/.env` (must exist) | `backend/.env` | `server/.env` |
| Compose file | `local/compose.yaml` | `local/compose.yaml` | `server/compose.yaml` |
| Project / volumes | `collections-app-dev` | `collections-app` | `collections-app-prod` |

dev and test have different ports and volumes, so they run side by side. Everything binds `127.0.0.1` only (AT-18).

```text
deploy/
├── dev  test  prod     the three commands (+ pitest, the test stack on the Pi)
├── lib.sh              shared helpers (help text, colors, env loading)
├── local/              dev + test: backend stack + Vite dev server on the frontend-web checkout
│   ├── compose.yaml
│   ├── dev.env
│   └── test.env
└── server/             prod + pitest on the Pi: GHCR images, release.sh, backups, alerts, logs, systemd units
    ├── compose.yaml
    ├── .env.example    → copy to .env (gitignored)
    └── check.sh
```

## dev and test (on your machine)

```bash
cp backend/.env.example backend/.env    # once: set POSTGRES_PASSWORD (URL-safe characters only)
./deploy/dev up -d                      # build and start; omit -d to follow the logs
./deploy/dev down                       # stop, data kept

./deploy/test up -d --fresh             # blank database every time you want one
./deploy/test down --fresh              # stop and wipe
./deploy/test logs -f api               # debug-level text logs
```

- The web container runs the Vite dev server on whatever branch `frontend-web/` has checked out, so edits reload live.
  The first start runs `npm ci` into a Linux-only `node_modules` volume (`--fresh` keeps it, so later starts are quick).
- `--fresh` deletes only test's database and uploaded files. dev has no `--fresh`: to reset dev, use `./deploy/dev down -v`.
- To change ports or log level, edit `local/dev.env` / `local/test.env`. Secrets never go there (the files are committed).
- Running the services on the host instead (Go and Node installed): see the `backend/` and `frontend-web/` READMEs.

## prod (home server)

Runs the whole app (Postgres, migrations, API, Caddy web) on a Raspberry Pi (arm64, 64-bit OS) from a clone of this repo.
The Pi **never builds**: a tag `vX.Y.Z` in the backend or web repo builds an arm64 image on GitHub Actions and pushes it to
GHCR; publishing a GitHub Release from that tag is the deploy approval (D-117). Every minute `collections-release.timer`
runs `deploy/server/release.sh`, which also fast-forwards this checkout, so pushed `deploy/` changes go live within a minute.

```text
 browser ──► WEB_BIND:WEB_PORT (LAN IP, port 80) ──► web (Caddy) ──► api ──► db (Postgres)
                                                       └ serves the SPA, proxies /api   └ volumes: pgdata, appdata
```

Only `web` publishes a port. `db` and `api` exist only on the compose network. The deployed versions are written by
`release.sh` to `deploy/server/versions.env` (gitignored).

The full step-by-step setup, restore and move-to-a-new-machine guide is kept off git, on your machine.

### First start

Prerequisites: Docker with Compose v2, `git`, `jq`, `zstd`, `rclone` (off-Pi backups), `ufw`.

```bash
git clone --recurse-submodules https://github.com/0xfederama/collections-app.git
cd collections-app
cp deploy/server/.env.example deploy/server/.env      # fill it in: see the comments in the file
sudo mkdir -p /srv/collection/backups && sudo chown "$USER" /srv/collection/backups
./deploy/prod check                                   # exposure check: must print "ok"
sudo cp deploy/server/systemd/collections-* /etc/systemd/system/ && sudo systemctl daemon-reload
sudo systemctl enable --now collections-release.timer collections-backup.timer collections-health.timer
journalctl -fu collections-release                    # wait for "backend X is live" and "web Y is live"
```

The units assume user `fede` and the clone at `/home/fede/collections-app`; edit `User=` and the paths otherwise.
Quote values with spaces in `.env` (`LOKI_HOST="a b"`): the wrapper reads it as a shell file.

#### Where the data lives

| What | Where | Owner |
|---|---|---|
| Postgres data | Docker named volume `collections-app-prod_pgdata` | the container's `postgres` user |
| Uploaded images | Docker named volume `collections-app-prod_appdata`, mounted at `/data` | UID/GID **65532** (the api's distroless `nonroot` user) |
| Backups | `BACKUP_DIR` in `deploy/server/.env`, default `/srv/collection/backups`, plus encrypted copies on Google Drive | the user running the backup unit |

Do not `chown` or edit inside the volumes by hand. `down` keeps them; `down --volumes` **deletes your data**.

Container hardening: all capabilities dropped (Postgres gets back the few it needs), `no-new-privileges`;
the api (UID 65532) and web (UID 10001) run with a read-only root filesystem.

### Reaching it from your other devices

The app has **no login screen of its own**: from backend 3.0.0 (F-027) the user comes from the signed Cloudflare Access
token, so the only way in from outside is the tunnel below. The stack itself must never be reachable from the internet.

- Set `WEB_BIND` to the Pi's LAN IP (reserved on the router) and `WEB_PORT=80`, and allow the LAN in ufw
  (`sudo ufw allow from 192.168.1.0/24 to any port 80 proto tcp`). Tailscale works too: bind to the Tailscale IP instead.
- **Never port-forward** on the router, never `0.0.0.0`, never a public address. `./deploy/prod check` refuses those.
- No TLS inside the stack (plain HTTP on the private network).

**From anywhere (roadmap #30): Cloudflare Tunnel + Access.** The optional `tunnel` service (`cloudflared`) opens an
outbound-only connection to Cloudflare, so no port is opened on the router. `collections.federama.dev` reaches the app
only after a Cloudflare Access login (allowed emails only, one-time email code); Access is the login, since the app has none.
- Enable: `COMPOSE_PROFILES=logs,tunnel` and `TUNNEL_TOKEN=` in `deploy/server/.env`, then `./deploy/prod up -d`.
- In Zero Trust: tunnel public hostname `collections.federama.dev` → `http://web:8080`; an Access application on that
  hostname with an Allow policy for the emails, session about 1 month; a Bypass policy for the public icon files
  (`/favicon*`, `/apple-touch-icon*`, `/icons/*`, `/manifest.webmanifest`), which iOS may fetch without the login cookie.
- Never a public hostname without the Access application in front: the tunnel would publish the app to the internet.
- The test stack never starts the tunnel (its profiles are cleared).

**Accounts (roadmap #31, F-027, backend 3.0.0 + web 3.0.0).** Set in `deploy/server/.env` before those releases reach prod
(the backend refuses to start in production without all three):
- `ACCESS_TEAM_DOMAIN` (`<team>.cloudflareaccess.com`) and `ACCESS_AUD` (the Access application's AUD tag): requests
  through the tunnel carry Cloudflare's signed `Cf-Access-Jwt-Assertion`, verified against them.
- `OWNER_EMAIL`: your Google email. Everything created before accounts becomes yours on the first 3.0.0 start, and every
  request from the home network (`raspberrypi.local`, the LAN IP: no Cloudflare headers) acts as you, always, with no
  switch and no redirect (D-150). Anyone on the home Wi-Fi is you; other people use `collections.federama.dev`, at home too.

### Releases (upgrade)

Publish a GitHub Release (as pre-release first, see pitest below; then mark it latest). Within a minute the Pi:

1. pulls the new image (if it isn't built yet, it waits and retries every minute);
2. backend only: stops the api, backs up, runs the new migrations on a throwaway copy of the database, then on the real one;
3. starts the new container and waits until it is healthy, else starts the old one again and alerts;
4. removes every image no container uses (old releases), so the SD card does not fill up.

Migrations must be backward compatible with the previous release (expand/contract, D-118), which is what makes step 3's
rollback safe. To force a check now: `./deploy/prod release`. Logs: `journalctl -u collections-release`.

**Old images left from before the automatic clean-up** (or after a failed deploy): `docker image prune -af` removes every
image no container uses; the running ones are kept, and a rollback re-pulls from GHCR if ever needed.

### Backups

Postgres **and** the uploaded images, together. The api is stopped for a few seconds while it runs.

```bash
./deploy/prod backup                    # → $BACKUP_DIR/<UTC timestamp>/{db.dump, files.tar.zst, manifest.json}
./deploy/prod prune                     # keep the newest backup of each of the last 7 days and 4 ISO weeks
./deploy/prod verify <backup-dir>       # compare the running database with a backup
./deploy/prod backup-status             # fails if the newest backup is missing, incomplete or older than 26 h
./deploy/prod offsite list|get <name>   # encrypted copies on Google Drive (rclone crypt remote OFFSITE_REMOTE)
```

`collections-backup.timer` runs backup, prune and the encrypted Drive upload nightly at 03:15 (`Persistent=true` catches
up after downtime) and pings `collections-backup`. rclone uses **our own Google Cloud client** (scope `drive.file`, consent screen published), never rclone's shared one,
which hits Google's quota; `drive.file` only sees files made by the same client ID, so rebuilds must reuse it.
The rclone config (Drive token and crypt passwords) lives only in your
password manager: without it the Drive copies cannot be read.

### Restore

```bash
./deploy/prod restore /srv/collection/backups/<timestamp> --force    # asks you to type "restore"
```

It verifies the files, replaces the database and images, runs `verify` and starts the api. The migrations come from the
running backend image, so restore a backup no newer than the deployed backend. Practise it once a year on the test stack
or a spare machine (`./deploy/pitest restore <backup>`).

### Everyday commands

```bash
./deploy/prod ps | logs -f api | restart api | down      # any docker compose command works
./deploy/prod check                                       # exposure check, also run it after editing deploy/server/.env
```

## pitest (test stack on the Pi, D-119)

A second, empty stack next to prod on the Pi: `./deploy/pitest` takes the same commands as `./deploy/prod`
(project `collections-app-pitest`, own volumes, `deploy/server/versions-test.env`, port `TEST_WEB_PORT`, 8081).

- Always on (no setting): allow the port on the LAN (`sudo ufw allow from 192.168.1.0/24 to any port 8081 proto tcp`).
- Flow: tag `vX.Y.Z`, publish the GitHub Release as a **pre-release**: test gets it within a minute. When it looks right, edit the release, untick pre-release and set it as latest: prod gets it.
- The release check runs test first; a failure there is logged as `[release test]` and never blocks prod. Same preflight and rollback, no backups.
- Always running: every release check (each minute) starts it again if it is down, empty if it was wiped, never as a
  lone service. Wipe it with `./deploy/pitest down -v`; it is back, empty, within a minute. A restore holds the
  stack's release lock, so it is never restarted mid-restore.
- Accounts (F-027): the test stack runs with fake dev users instead of Access (`APP_ENV=development`, `DEV_IDENTITY=true`,
  set by `deploy/prod` for the test stack only; prod refuses them): you (`OWNER_EMAIL`), `alice@dev.test` and
  `bob@dev.test`, picked with the switcher in the web app. Home only: never on the tunnel, no Cloudflare login.

## Alerts (healthchecks.io, roadmap #24)

The Pi never sends mail: it pings healthchecks.io, which notifies you (email, Telegram, ntfy, Signal, …).
Set `HC_PING_KEY` in `deploy/server/.env`; the checks are created on the first ping. Then set each check's schedule:

| Check | Pinged by | Set period / grace | Alerts when |
| --- | --- | --- | --- |
| `collections-release` | every finished prod release run (each minute) | 1 min / 15 min | no successful run for 15 min: expired token, dead timer, Pi offline |
| `collections-deploy` | each prod deploy | 365 days / 1 day | a deploy failed and rolled back, or an image is still missing an hour after its release |
| `collections-backup` | the nightly backup unit (backup, prune, Drive upload) | cron `15 3 * * *`, your time zone / 2 h | the backup failed, or did not run (stale) |
| `raspberrypi` | `collections-health.timer`, every minute | 1 min / 5 min | disk over `HEALTH_DISK_MAX`%, memory low, a prod container unhealthy, or the Pi is off |

A release waiting for its image (build still running) is not an alert. Test stack (`pitest`) failures are only logged.
Install the health timer: `sudo cp deploy/server/systemd/collections-health.* deploy/server/systemd/collections-backup.service /etc/systemd/system/ && sudo systemctl daemon-reload && sudo systemctl enable --now collections-health.timer`.

## Hosted logs and latency charts (Grafana Cloud, roadmap #25, D-128)

Prod containers log to the systemd journal (`docker logs` and `./deploy/prod logs` still work). The optional `logs`
service (Fluent Bit, capped at 48 MB and a quarter CPU) ships the prod containers' and the `collections-*` units' lines to
Grafana Cloud Loki (free tier). Latency comes from the API's own request log (`duration_ms`); there is no metrics agent.

- Enable: in `deploy/server/.env` set `COMPOSE_PROFILES=logs`, `LOKI_HOST`, `LOKI_USER`, `LOKI_TOKEN`; the next minute's
  re-apply (or `./deploy/prod up -d`) starts it. Disable: empty `COMPOSE_PROFILES`, then `./deploy/prod up -d --remove-orphans`.
- Dashboard: Grafana → Dashboards → Import → `deploy/server/logs/grafana-dashboard.json`, pick the Loki data source.
- The test stack never ships logs.
