# Backup & Deployment

## 1. Local development

Prerequisites (exact versions are recorded by task R-1 in each README): Git, Go, Node LTS + npm, Docker with Compose v2, and `gh`.

```bash
git clone --recurse-submodules https://github.com/0xfederama/collections-app.git /Users/federico/Developer/collections-app
```

This checks out `backend/` and `frontend-web/` (submodules, D-043). Whole app in one command: `cp backend/.env.example backend/.env`
(set `POSTGRES_PASSWORD`), then `./deploy/dev up -d` from the parent folder. Three environments, one command each (D-073,
guide in `deploy/README.md`): `./deploy/dev` (persistent local, ports 8080/5173), `./deploy/test` (own project and volumes,
ports 8090/5183, `--fresh` wipes its data) and `./deploy/prod` (home server, §5). Local settings are in `deploy/local/{dev,test}.env`
(committed, no secrets); local secrets stay in `backend/.env`.

Backend (from `backend/`): `cp .env.example .env` → `docker compose up --build` (db + migrate + api, the primary path, D-033).
Optional fast loop: copy the opt-in override that publishes `127.0.0.1:5432`, run `docker compose up -d db`, then `make migrate` and `make run` on the host.
Web: `cp .env.example .env` → `npm ci` → `npm run dev` (Vite proxies `/api` to `API_PROXY_TARGET`, default `http://localhost:8080`).

| Service | URL | Exposure |
|---|---|---|
| Web (Vite) | http://localhost:5173 | localhost |
| API | http://localhost:8080 | published as `127.0.0.1:8080:8080` only |
| Postgres | `db:5432` | Docker network only. For local tools use `docker compose exec db psql`, or an opt-in `compose.override.yaml` example that publishes `127.0.0.1:5432` |

Both READMEs must document: start/stop, migrate, test/lint, health check, logs (`docker compose logs -f api`),
**safe reset** (`make reset-dev`, which prompts before deleting volumes and refuses to run if `APP_ENV=production`), and the
troubleshooting list (archive §12.7: tool versions, port conflicts, DB connection, unapplied migrations, env vars, CORS,
stale generated client, storage permissions).

## 2. Compose (backend repo, `compose.yaml`)

- `db`: official `postgres` image (version from R-1), named volume `pgdata`, healthcheck with `pg_isready`, no published ports.
- `migrate`: golang-migrate image, runs `up` once and depends on `db` being healthy.
- `api`: built from the Dockerfile (multi-stage build, distroless or alpine runtime, non-root UID), named volume `appdata` mounted at `/data`. It depends on `migrate` completing successfully, has a healthcheck on `/readyz`, uses `restart: unless-stopped`, and publishes `127.0.0.1:${API_PORT:-8080}:8080`.

## 3. Environment variables

### Backend
| Var | Default | Notes |
|---|---|---|
| `APP_ENV` | `development` | `development` \| `production` |
| `HTTP_ADDR` | `:8080` | Listen address inside the container |
| `DATABASE_URL` | — (required) | `postgres://collection:<pw>@db:5432/collection?sslmode=disable` (in-network) |
| `DB_MAX_CONNS` | `10` | pgx pool |
| `DATA_DIR` | `/data` | Must exist and be writable, or startup fails |
| `ACCESS_TEAM_DOMAIN`, `ACCESS_AUD` | — | Cloudflare Access team host + app AUD tag; both or neither; required in production (F-027) |
| `OWNER_EMAIL` | — | Owner of pre-accounts data and of every home-network request (D-150); required in production |
| `DEV_IDENTITY` | `false` | Fake dev users (dev and the Pi test stack only); refused in production |
| ~~`CORS_ALLOWED_ORIGINS`~~ | — | Dropped (D-033): dev uses the Vite proxy, so it's same-origin everywhere |
| `LOG_LEVEL` | `info` | |
| `LOG_FORMAT` | `json` | `json` \| `text` |
| `POSTGRES_PASSWORD` | — | Compose only. Placeholder in `.env.example` |

### Web
| Var | Default | Notes |
|---|---|---|
| `API_PROXY_TARGET` | `http://localhost:8080` | Vite dev-server proxy target for `/api` (D-033; replaces `VITE_API_BASE_URL`). The app always calls the relative `/api` |

## 4. Backup & restore

Postgres plus `DATA_DIR/images` together. A DB-only backup is **insufficient**.

`scripts/backup.sh [dest]` (backend repo):
1. `docker compose stop api`, which pauses writes. This is simplest and correct for two users, and the downtime is seconds.
2. `pg_dump -Fc` → `dest/<timestamp>/db.dump`.
3. `tar` of `/data/images` → `dest/<timestamp>/files.tar.zst`.
4. Write `manifest.json` (timestamp, migration version, app version, sha256 of both files).
5. `docker compose start api`. The api is restarted even when a step fails (trap).

`scripts/restore.sh <backup-dir>`: refuses non-empty target volumes unless `--force` is given, which prompts. It verifies the manifest hashes,
restores the dump into a fresh DB, extracts the files, runs `migrate up` (to support a newer app version), and starts the api.

`scripts/verify-restore.sh`: compares counts per table with the manifest and checks every `attachments.storage_key` and
thumbnail exists with a matching sha256 on the original. It also checks that every item's latest content version body matches the backup.

Rules: run a backup **before every migration in production** (the README upgrade steps include this). Backups never go into Git.
Keep at least 7 daily and 4 weekly copies off the device (user's choice of location, documented).

## 5. Production / home-server deployment (Raspberry Pi or Linux)

- `deploy/server/compose.yaml` (run through `./deploy/prod`, D-073) lives in the **parent repo** and **builds** both images on the server from the `backend/` and `frontend-web/` submodules (D-069: no registry, native arch, arm64 on a Pi), plus `db` and `migrate`.
- The `web` container (Caddy) serves the SPA and reverse-proxies `/api/*` to `api:8080`, so it's same-origin and needs no CORS. It's published on `127.0.0.1:8081` by default, or on the LAN interface or a Tailscale IP **by explicit opt-in**.
- **Recommended remote access:** Tailscale (or equivalent private VPN) on the host, with no router port-forwarding. **Never** expose to the public internet until Phase 3 auth exists.
- Persistent data: Docker named volumes `pgdata` and `appdata` (D-071); only backups are a host path, `/srv/collection/backups`. See `deploy/README.md`.
- Upgrade: backup → `git pull --recurse-submodules` → rebuild images → `migrate up` → restart → check `/readyz`. Rollback: restore the backup taken before the upgrade (a migration `down` doesn't restore files and may lose data).
- No images are published (D-069). Publishing to a registry later is outward-facing, so an agent asks the user before configuring it.
