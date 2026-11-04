# Running the app

Three environments, one command each. Every command takes any `docker compose` subcommand (`ps`, `logs -f api`,
`restart web`, `exec db psql -U collection`, ...) plus a few extras, and `--help` prints its usage.

| | `./deploy/dev` | `./deploy/test` | `./deploy/prod` |
|---|---|---|---|
| For | Automated checks: unit, integration, e2e, smoke (agents) | Your manual testing | The real app (Raspberry Pi, LAN) |
| Web | http://localhost:5183 (Vite, hot reload) | http://localhost:5173 (Vite, hot reload) | http://127.0.0.1:8081 (Caddy, built SPA) |
| API | http://localhost:8090 | http://localhost:8080 | not published (behind web) |
| Data | Disposable: `--fresh` wipes it | Persistent, never touched by agents | Persistent, with backups |
| Settings | `local/dev.env` | `local/test.env` | `server/.env` (from `server/.env.example`) |
| Secrets | `backend/.env` (must exist) | `backend/.env` | `server/.env` |
| Compose file | `local/compose.yaml` | `local/compose.yaml` | `server/compose.yaml` |
| Project / volumes | `collections-app-dev` | `collections-app` | `collections-app-prod` |

dev and test have different ports and volumes, so they run side by side. Everything binds `127.0.0.1` only (AT-18).

```text
deploy/
├── dev  test  prod     the three commands
├── lib.sh              shared helpers (help text, colors, env loading)
├── local/              dev + test: backend stack + Vite dev server on the frontend-web checkout
│   ├── compose.yaml
│   ├── dev.env
│   └── test.env
└── server/             prod: images built on the server (Caddy web + api), backups, exposure check
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

Runs the whole app (Postgres, migrations, API, Caddy web) from a clone of this repo, on a Raspberry Pi (arm64) or a
Linux box (amd64). Images are **built on the server** (D-069): no registry, nothing is published anywhere.

```text
 browser ──► 127.0.0.1:8081 (or your Tailscale IP) ──► web (Caddy) ──► api ──► db (Postgres)
                                                          └ serves the SPA, proxies /api   └ volumes: pgdata, appdata
```

Only `web` publishes a port. `db` and `api` exist only on the compose network.

### Prerequisites

- Docker with Compose v2 (running), `git`, `jq` (backups), optionally `zstd` (otherwise backups use gzip).
- Disk for the images and build cache (the first build downloads Go, Node and base images), plus room for your data and backups.
- A Pi needs a 64-bit OS. The first build there is slow (the Go and Node builds run natively); check `docker stats` if it struggles.

### First start

```bash
git clone --recurse-submodules https://github.com/0xfederama/collections-app.git
cd collections-app
cp deploy/server/.env.example deploy/server/.env      # set POSTGRES_PASSWORD (openssl rand -hex 24)
sudo mkdir -p /srv/collection/backups && sudo chown "$USER" /srv/collection/backups   # or set BACKUP_DIR in .env to a folder you own
./deploy/prod check                     # exposure check: must print "ok"
./deploy/prod up -d --build             # first build is slow, later ones use the cache
curl -fsS http://127.0.0.1:8081/readyz  # prints "ready"
```

Open `http://127.0.0.1:8081`. Quote values with spaces in `.env` (`WORKSPACE_NAME="Our Collection"`): the `./deploy/prod` wrapper reads it as a shell file.
Already cloned without submodules: `git submodule update --init --recursive`.

#### Where the data lives

| What | Where | Owner |
|---|---|---|
| Postgres data | Docker named volume `collections-app-prod_pgdata` | the container's `postgres` user (set up by the image) |
| Uploaded images | Docker named volume `collections-app-prod_appdata`, mounted at `/data` | UID/GID **65532** (the api's distroless `nonroot` user) |
| Backups | `BACKUP_DIR` in `deploy/server/.env`, default `/srv/collection/backups` | the user who runs `./deploy/prod backup` (mode 0700 inside) |

Named volumes (D-071) rather than `/srv/collection/{pgdata,data}` bind mounts: Docker creates them with the right owner,
and the backup/restore scripts wipe and refill volumes by name. To inspect them: `docker volume inspect collections-app-prod_appdata`.
Do not `chown` or edit inside them by hand. `docker compose down` keeps them; `down --volumes` **deletes your data**.

Container hardening: all capabilities dropped (Postgres gets back the few it needs to start), `no-new-privileges`;
the api (UID 65532) and web (UID 10001) run with a read-only root filesystem.

#### Trying prod next to another stack

To rehearse on a machine that already runs prod (or just to try it): `PROD_PROJECT=collections-app-trial ./deploy/prod …` uses its own
containers and volumes (leave it unset on the real server), and a different `WEB_PORT` and `BACKUP_DIR` in `.env` keep it from clashing.
Remove it with `PROD_PROJECT=collections-app-trial ./deploy/prod down --volumes`, always with the same variable set.

### Reaching it from your other devices

The app has **no login** (auth is Phase 3). It must never be reachable from the internet.

- **Never port-forward** on your router and never publish this on a public IP.
- Recommended: install [Tailscale](https://tailscale.com/) on the server and your devices, then in `deploy/server/.env` set
  `WEB_BIND` to the server's Tailscale IP (`tailscale ip -4`) and run `./deploy/prod up -d`. Only devices in your tailnet can then connect.
- `WEB_BIND` must be one specific address. `./deploy/prod check` refuses `0.0.0.0` and any published port other than
  the web one, and prints a note when an opt-in address is used.
- There is no TLS inside the stack (plain HTTP over the private network, Tailscale encrypts the traffic).

### Backups

Postgres **and** the images, together (a DB-only backup is not enough). The api is stopped for a few seconds while it runs.

```bash
./deploy/prod backup                    # → $BACKUP_DIR/<UTC timestamp>/{db.dump, files.tar.zst|gz, manifest.json}
./deploy/prod prune                     # keep the newest backup of each of the last 7 days and 4 ISO weeks
./deploy/prod verify <backup-dir>       # compare the running database with a backup
```

**Schedule it** with the systemd units in `deploy/server/systemd/` (nightly backup at 03:15, then prune; `Persistent=true`
catches up after downtime). Edit `User=` and the paths if your clone isn't `/home/pi/collections-app`, then:

```bash
sudo cp deploy/server/systemd/collection-backup.{service,timer} /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now collection-backup.timer
systemctl list-timers collection-backup.timer   # next run
sudo systemctl start collection-backup.service  # optional: run one now
journalctl -u collection-backup.service         # its log
```

**Check that it ran:** `./deploy/prod backup-status` fails (non-zero, with the reason) when there is no backup, the newest
has no `manifest.json`, or it is older than 26 hours (`./deploy/prod backup-status 48` for another limit). Run it now and
then, or after the server was off.

**Copy backups off the device** (another machine, a NAS, cloud storage you control): the same disk dying takes the live
data and the backups together. Example, from another machine on your tailnet:
`rsync -a --delete pi@server:/srv/collection/backups/ ~/collection-backups/`. Backups hold all your data and are not
encrypted, so never put them in Git and treat the destination accordingly.

### Upgrade

```bash
./deploy/prod backup                         # 1. always first: a migration cannot be undone safely
git pull --recurse-submodules                # 2. new code (updates backend/ and frontend-web/ to the pinned commits)
./deploy/prod up -d --build                  # 3. rebuild images; `migrate` runs before the api starts
./deploy/prod ps                             # 4. migrate = exited (0), the others healthy
curl -fsS http://127.0.0.1:8081/readyz
```

**One-off steps after specific upgrades:** none at the moment. (The old `strip-images` backfill of 1.2.1 was removed with the F-019 refactor; production was not in use.) Add a row here when a release needs a manual step.

If `migrate` fails, the api does not start (the old one is already replaced, so the app is down): read
`./deploy/prod logs migrate`, then roll back.

### Rollback

A migration `down` does not bring back files and can lose data, so rollback means restoring the backup from step 1 with the old code:

```bash
git checkout <previous parent commit> && git submodule update --init --recursive
./deploy/prod restore /srv/collection/backups/<timestamp> --force    # asks you to type "restore"
./deploy/prod up -d --build
```

`restore` refuses a backup newer than the checked-out migrations, so go back to the old code first.

### Restore drill (do it once before you need it)

On a spare machine or after a deliberate wipe: `./deploy/prod down --volumes`, then
`./deploy/prod restore <backup>` (no `--force` needed on empty volumes), then `./deploy/prod up -d --build`,
and check your items and images in the browser. `restore` runs `verify` itself before it starts the api.

### Everyday commands

```bash
./deploy/prod ps | logs -f api | restart api | down      # any docker compose command works
./deploy/prod check                                       # exposure check, also run it after editing deploy/server/.env
```

## pitest (test stack on the Pi, D-119)

A second, empty stack next to prod on the Pi: `./deploy/pitest` takes the same commands as `./deploy/prod`
(project `collections-app-pitest`, own volumes, `deploy/server/versions-test.env`, port `TEST_WEB_PORT`, 8081).

- Enable: `TEST_STACK=1` in `deploy/server/.env`, and allow the port on the LAN (`sudo ufw allow from 192.168.1.0/24 to any port 8081 proto tcp`).
- Flow: tag `vX.Y.Z`, publish the GitHub Release as a **pre-release**: test gets it within a minute. When it looks right, edit the release, untick pre-release and set it as latest: prod gets it.
- The release check runs test first; a failure there is logged as `[release test]` and never blocks prod. Same preflight and rollback, no backups.
- Wipe it: `./deploy/pitest down -v`.
