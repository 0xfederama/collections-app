# Collections App

A calm, image-forward place for two people to collect and compare things they like or want: movies to watch,
motorcycles to consider, things to buy. One shared workspace with nested **folders**, **lists** and **items**. Items have
rich fields, one image, and a Markdown description with version history.

This is the **parent repo**. It ties the two service repos together as git submodules and holds the design docs and the
whole-app local setup. The service code lives in the submodules.

| Path | What | Repo |
|---|---|---|
| `backend/` | Go API + PostgreSQL + the canonical OpenAPI contract | [collections-app-backend](https://github.com/0xfederama/collections-app-backend) (submodule) |
| `frontend-web/` | React + TypeScript + Vite web app | [collections-app-frontend-web](https://github.com/0xfederama/collections-app-frontend-web) (submodule) |
| `design-docs/` | Product, architecture, API, data model, decisions, status, agent workflow | this repo |
| `compose.yaml` | Whole-app local dev: db + migrate + api + Vite dev server | this repo |

## Quick start

Prerequisites: Git, Docker with Compose v2. (Go 1.27 and Node 24 are only needed if you run the services on the host.)

```bash
git clone --recurse-submodules https://github.com/0xfederama/collections-app.git
cd collections-app
cp backend/.env.example backend/.env      # set POSTGRES_PASSWORD (URL-safe characters only)
docker compose up --build
```

| Service | URL | Exposure |
|---|---|---|
| Web (Vite dev server) | http://localhost:5173 | `127.0.0.1` only (`WEB_PORT` overrides the port) |
| API | http://localhost:8080 (`/healthz`, `/readyz`) | `127.0.0.1` only (`API_PORT` in `backend/.env` overrides) |
| Postgres | `db:5432` | Docker network only, not published |

Stop with `docker compose down`. Add `-v` to also delete the database and uploaded files.

**Throwaway sandbox (empty DB every start).** To play without keeping anything, add the `compose.fresh.yaml` override:

```bash
docker compose -f compose.yaml -f compose.fresh.yaml up --build
```

The database and uploaded files live in memory (tmpfs), so every stop wipes them and every start re-runs the migrations on
a blank DB. It runs as a separate project (`collections-app-fresh`), so your normal data is never touched, but it uses
the same ports, so stop the normal stack first. Tear down with the same `-f` pair plus `down`.
Already cloned without `--recurse-submodules`: `git submodule update --init --recursive`.

The first start is slower: the `web` container runs `npm ci` into a Linux-only `node_modules` volume.
The header of the web app shows `Backend: ready` once the dev proxy reaches the API.

## How the app fits together

```text
 Browser ──► Vite dev server :5173 (dev)   or   Caddy (prod, later: Q-03)
               │  relative /api, /healthz, /readyz are proxied: same origin, so no CORS anywhere
               ▼
            Go API :8080  (chi router, pgx)
               ├── PostgreSQL   all relational data + Markdown content/versions
               └── DATA_DIR     image originals + thumbnails (a volume)
```

- **Same-origin by design (D-033, D-016).** The browser only calls relative `/api/...`. In dev Vite forwards it, in
  production Caddy will. There is no CORS code.
- **Contract first.** The backend owns `backend/api/openapi.yaml` (OpenAPI 3.0.3, arrives in B-03). The web app vendors a
  pinned copy and generates its API client from it, so the two repos never drift silently.
- **Postgres holds everything relational**, including Markdown content and its versions. Only image files live on disk.
- **No monorepo (D-001).** Two independently buildable repos, joined by this parent repo (D-043).

### Stack

| Layer | Choices (versions and sources: `design-docs/DECISIONS.md` "Toolchain versions") |
|---|---|
| Backend | Go 1.27, chi, pgx v5, sqlc (B-02), golang-migrate, `log/slog`, testcontainers-go, golangci-lint |
| Database | PostgreSQL 18 (`pg_trgm` for search later) |
| Contract | OpenAPI 3.0.3, oapi-codegen strict chi server, Redocly lint (B-03) |
| Web | React 19, TypeScript 6 (strict), Vite 8, Tailwind 4, React Router 8 |
| Web, later tasks | TanStack Query, openapi-fetch, Radix UI primitives, dnd-kit, CodeMirror 6, react-markdown, Fontsource |
| Tests | Go: `go test` + real Postgres. Web: Vitest + Testing Library (jsdom). E2E: Playwright + axe (Q-01) |

## What the product does (MVP)

| Concept | Rules |
|---|---|
| Workspace | Exactly one, auto-created on first start. Anonymous edits (no accounts yet) |
| Folder | Nests without a depth limit, manually ordered |
| List | Lives at the root or in a folder. Display mode `compact`/`thumbnail`/`grid`, sort `manual`/`title`/`updated` |
| Item | Belongs to one list. Kinds: `generic`, `movie`, `tv_show`, `motorcycle`, `car`, `camera`, each with optional structured fields |

Also in the MVP: one image per item (upload or URL, thumbnails generated), Markdown description with history and restore,
move and drag-reorder, title search, three external links per item (Google, Reddit, official site), soft-delete Trash with
batch restore and purge, optimistic-concurrency conflict handling for two simultaneous editors, and light/dark theme.
Full spec: [design-docs/PRODUCT.md](design-docs/PRODUCT.md) and [UI_SPEC.md](design-docs/UI_SPEC.md).

**Not in the MVP** (hard scope fence): accounts or auth, TMDB lookups, public API, AI features, real-time collaboration,
offline mode, multiple images per item.

## Security boundary

There is **no authentication** in the MVP, so the API must never be reachable from the public internet.

- Compose publishes every port on `127.0.0.1` only. `make check` in `backend/` fails if that ever changes (AT-18).
- Reaching it from another device is an explicit opt-in. The recommended way is a private VPN such as Tailscale.
- Never commit secrets: `.env` files are gitignored, `.env.example` files hold blank placeholders. Don't write
  `user:pass@host` URLs in tracked files (the repo is scanned by GitGuardian). Pass credentials as `?user=…&password=…`.

## Configuration

| Where | File | What |
|---|---|---|
| `backend/.env` | from `backend/.env.example` | `POSTGRES_PASSWORD` (required), `API_PORT`, `APP_ENV`, `LOG_LEVEL`, `LOG_FORMAT`, `WORKSPACE_NAME`, host-loop `DATABASE_URL`/`DATA_DIR`. Validated at startup, the API refuses to start on bad values |
| `./.env` (optional) | from `.env.example` | `WEB_PORT` for the parent compose |
| `frontend-web/.env` (optional) | from `frontend-web/.env.example` | `API_PROXY_TARGET` for the Vite dev proxy (host runs only; the parent compose sets it to `http://api:8080`) |

Full variable table: [design-docs/BACKUP_AND_DEPLOYMENT.md](design-docs/BACKUP_AND_DEPLOYMENT.md) §3.

## Ways to run it

| Mode | Command | When |
|---|---|---|
| Everything in containers | `docker compose up --build` (this folder) | Default. One command, nothing to install but Docker |
| Backend in Docker, web on the host | `cd backend && docker compose up --build`, then `cd frontend-web && npm ci && npm run dev` | Faster frontend iteration with your own editor tooling |
| API on the host too | `cd backend`, copy `compose.override.example.yaml` to `compose.override.yaml`, `docker compose up -d db`, `make migrate`, `make run` | Debugging the Go code |

## Quality gates (there is no CI)

No GitHub Actions or Dependabot for now (D-031). Gates run locally, and the result is pasted into each PR (D-032).

| Repo | Command | Covers today |
|---|---|---|
| `backend/` | `make check` (Docker must be running) | gofmt, golangci-lint (goimports, noctx), `go test ./...` with a real Postgres, compose exposure check, Docker build |
| `frontend-web/` | `npm run check` | Prettier, ESLint, `tsc`, Vitest, `vite build` |
| either | `make audit` / `npm run audit` | Vulnerability scans (need network, not part of `check`) |

Later tasks extend the gates: B-02/B-03 add sqlc and OpenAPI drift checks, W-02 adds the API contract check, Q-01 adds Playwright.

## Environments, logs and health

- **Environments.** `APP_ENV` is `development` or `production`. Today it changes almost nothing (it is validated, logged, and
  `make reset-dev` refuses to run in `production`). The real variants are the three run modes above. A production
  deployment (published images, Caddy, backups) is planned in Q-02/Q-03, see BACKUP_AND_DEPLOYMENT §4–5.
- **Logs.** Structured `log/slog`: `LOG_FORMAT=json|text`, `LOG_LEVEL=debug|info|warn|error`. View with
  `docker compose logs -f api`. Request IDs, access logs and panic recovery arrive in B-04.
- **Health.** `/healthz` is liveness (process is up). `/readyz` is readiness (database answers and the data directory is writable;
  failures return a terse 503 with no paths or SQL).
- **Metrics and tracing** are out of scope for a two-person home deployment.

## Status and roadmap

Current progress is always in [design-docs/STATUS.md](design-docs/STATUS.md). The task plan with dependencies is
[design-docs/IMPLEMENTATION_PLAN.md](design-docs/IMPLEMENTATION_PLAN.md).

| Milestone | Content |
|---|---|
| M0 Bootstrap | Researched toolchain, backend and web skeletons, local gates (**done 2026-10-14**) |
| M1 Contracts | Database schema (B-02), OpenAPI spec (B-03), web API client (W-02). You review schema and spec |
| M2 Core | Backend foundations, workspace, folders, lists, items. Web design system, shell, tree, list view |
| M3 / M4 | Backend content, images, trash, search. Web item detail/edit, images, Markdown editor, search, trash, settings |
| M5 Integration | Playwright e2e, backup and restore scripts, production compose, fresh-clone check, final review |

After the MVP: Phase 2 TMDB lookups, Phase 3 accounts and access control (required before any public exposure), Phase 4 public API.

## Working with submodules

1. Work and push **inside the submodule** (`cd backend`, `git switch -c ...`, commit, open a PR in that repo).
2. After the PR merges, bump the pointer in the parent: `git -C backend switch main && git -C backend pull`, then
   `git add backend && git commit -m "chore: bump backend"`.
3. Update all submodules to their latest remote `main`: `git submodule update --remote --merge`.

Submodules check out a detached commit by default, so run `git switch <branch>` inside one before editing.

> **Pointer caution.** While a PR is open, the parent can point at a commit that exists only on the PR branch. If that PR is
> then **squash-merged** and its branch deleted, the recorded commit disappears and fresh recursive clones fail. Bump the
> pointer to the merged `main` commit right after merging, and prefer a merge commit or rebase merge for PRs the parent already references.

## Documentation map

| Doc | Read it for |
|---|---|
| [design-docs/README.md](design-docs/README.md) | Reading order, precedence, session rules |
| [PRODUCT.md](design-docs/PRODUCT.md), [UI_SPEC.md](design-docs/UI_SPEC.md) | What to build and how it looks |
| [ARCHITECTURE.md](design-docs/ARCHITECTURE.md), [DATA_MODEL.md](design-docs/DATA_MODEL.md), [API.md](design-docs/API.md) | How it is built |
| [DECISIONS.md](design-docs/DECISIONS.md) | Every decision (D-NNN), open questions, toolchain versions |
| [BACKUP_AND_DEPLOYMENT.md](design-docs/BACKUP_AND_DEPLOYMENT.md) | Run, configure, back up, deploy |
| [AGENT_WORKFLOW.md](design-docs/AGENT_WORKFLOW.md), [handoffs/](design-docs/handoffs) | How AI sessions work on this project |
| `backend/README.md`, `frontend-web/README.md` | Per-service setup, commands, troubleshooting |

## Troubleshooting

- **`web` container restarts or shows npm errors:** `docker compose logs web`. If `node_modules` got out of sync, run
  `docker compose down` and `docker volume rm collections-app_web_node_modules`, then start again.
- **`db` exits with "superuser password is not specified":** `POSTGRES_PASSWORD` in `backend/.env` is empty.
- **Port already in use:** set `API_PORT` in `backend/.env` or `WEB_PORT` in `./.env`.
- **Empty `backend/` or `frontend-web/` folders:** the submodules are not initialised, run `git submodule update --init --recursive`.
- **`Backend: down` in the web header:** `docker compose ps` should show `api` healthy. Check `curl -fsS http://127.0.0.1:8080/readyz`.
- **Service-specific problems:** see the troubleshooting sections of the two service READMEs.

## License

Not decided yet (design-docs/DECISIONS.md Q-4). Until then: all rights reserved.
