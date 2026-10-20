# Implementation Plan

Task IDs: `B-` backend, `W-` web, `Q-` integration/QA/DevOps, `R-` research (dispatch to `researcher`, sonnet).
Each task is meant to be **one PR** (AGENT_WORKFLOW §3). Live progress is tracked in [STATUS.md](STATUS.md). "Deps" must be merged first. Tests for each task are
part of that task (usually written by `test-writer`). Docs are updated by `docs-keeper` before the PR.

## M0 — Bootstrap (both repos in parallel)

| ID | Task | Deps |
|---|---|---|
| M0-U | ~~User: create private repos and clone them~~ **Done 2026-10-13** (`0xfederama/collections-app-backend`, `0xfederama/collections-app-frontend-web`). License still open (DECISIONS Q-4) | — |
| R-1 | Verify current stable versions and maintenance status of every tool in ARCHITECTURE §2–3 (Go, PG, chi, pgx, sqlc, golang-migrate, golangci-lint, testcontainers-go, x/image, EXIF lib, Node LTS, React, Vite, TS, TanStack Query, React Router, Tailwind, Radix vs React Aria, dnd-kit, CodeMirror 6, react-markdown, openapi-typescript/openapi-fetch, Vitest, MSW, Playwright, axe, Caddy). Output a table with versions, source links, and date into DECISIONS.md | — |
| R-2 | OpenAPI tooling: compare oapi-codegen vs ogen for chi + 3.1 support; pick the spec version and linter (Redocly vs Spectral) | — |
| B-00 | Skeleton: go.mod, `cmd/api` with health endpoints, config, slog, graceful shutdown, Makefile (`check`, `test`, `lint`, `migrate`, `generate`, `run`), Dockerfile, compose.yaml (pg + migrate + api, 127.0.0.1), `.env.example`, README, **CLAUDE.md from template**, `.claude/agents/*`, PR template, `docs/` skeleton | R-1 |
| B-01 | ~~CI workflow + Dependabot~~ **Dropped 2026-10-13 (D-031)**: the local `make check` from B-00 replaces it | — |
| W-00 | Skeleton: Vite React TS strict, Tailwind, ESLint/Prettier, Vitest, router plus AppShell placeholder, `npm run check`, Vite dev proxy `/api` (D-033), `.env.example`, README, **CLAUDE.md from template**, `.claude/agents/*`, PR template, `docs/` skeleton. ~~Playwright config, Dockerfile + Caddyfile~~ → Q-01/Q-03 (D-033) | R-1 |
| W-01 | ~~CI workflow + Dependabot~~ **Dropped 2026-10-13 (D-031)**: the local `npm run check` from W-00 replaces it | — |

Brief for the whole of M0 (one session): [handoffs/M0.md](handoffs/M0.md). Later deps on B-01/W-01 now mean B-00/W-00.
Wherever a later task says "in CI", read it as "in the local `make check` / `npm run check`" until CI is reintroduced (D-031).

**Checkpoint C0.**

## M1 — Contracts (serialize; user review gate)

| ID | Task | Deps |
|---|---|---|
| B-02 | Migration 000001: full schema from DATA_MODEL §2 + pg_trgm; up/down/up in the local `make check`; sqlc config + empty query files compiling | B-00 |
| B-03 | `api/openapi.yaml` v0.1 covering **all** of API.md, with examples; codegen wired; lint in CI; tag `api-v0.1.0` after merge | B-00, R-2, **B-02** (M1 is serialized) |
| W-02 | `scripts/api-sync.mjs`, `api:sync` / `api:check` scripts, vendor `api-v0.1.0`, generate client, `lib/api` wrapper (ETag→If-Match, problem → `ApiError`), MSW handlers from spec examples | B-03 |

**Checkpoint C1: the user reviews the schema and spec.**

## M2 — Core (backend and web in parallel)

| ID | Task | Deps |
|---|---|---|
| B-04 | Foundations: `database.InTx`, error→problem mapping, ETag/If-Match middleware helpers, unknown-field rejection, request limits, request id (CORS dropped, D-033) | B-03 |
| B-05 | Workspace bootstrap + settings endpoints (AT-02) | B-04 |
| B-06 | Folders and lists: CRUD, tree endpoint, move with cycle check, reorder (AT-03, AT-04, AT-21) | B-04 |
| B-07 | Items: CRUD, kind validator registry for all 6 MVP kinds (DATA_MODEL §2.1), list items with sort/filter/pagination, move, reorder (AT-05) | B-06 |
| W-03 | Design system: tokens for light **and dark** themes, no-flash theme bootstrap, fonts, all `components/ui` primitives with states + a `/dev/ui` gallery route (dev only) | W-00 |
| W-04 | AppShell responsive (drawer / rail / sidebar / detail panel), sidebar tree with expand persistence, breadcrumbs | W-02, W-03 |
| W-05 | Folder/list CRUD dialogs, move picker, tree drag-reorder | W-04 |
| W-06 | List view: 3 display modes, sort, filter, item drag-reorder, fallback tiles | W-04 |

## M3 — Backend features

| ID | Task | Deps |
|---|---|---|
| B-08 | Content: get/put/versions/restore with retention (AT-08 backend part) | B-07 |
| B-09 | Storage + images: FileStore, sniffing, thumbnails, PUT/DELETE image, file serving, orphan sweeper (AT-06, AT-07, AT-20) | B-07 |
| B-10 | Trash: batch delete for folder/list/item, list, restore (+destination), purge incl. files (AT-11) | B-08, B-09 |
| B-11 | Search (AT-12) | B-07 |
| B-12 | `GET /api/v1/recent-items` for Home (D-070, W-13 contract gap), then tag `api-v0.2.0` | B-11 |

## M4 — Web features

| ID | Task | Deps |
|---|---|---|
| W-07 | Item detail view + 3 links + per-kind field configs and sections for all 6 kinds (AT-13) | W-06, B-07 |
| W-08 | Item edit form, unsaved guard, 422 mapping, conflict UX (AT-09 web, AT-22) | W-07 |
| W-09 | Image dropzone/picker/URL/remove with progress | W-08, B-09 |
| W-10 | Markdown editor (CodeMirror) + safe preview + history drawer + restore (AT-08 web) | W-08, B-08 |
| W-11 | Search (global dropdown + page) | W-04, B-11 |
| W-12 | Trash page with restore/restore-to/purge flows | W-05, B-10 |
| W-13 | Settings page (incl. theme override) + home page | W-08, B-05 |

**Checkpoint C3.**

## M5 — Integration, ops, hardening

| ID | Task | Deps |
|---|---|---|
| Q-01 | ~~Playwright e2e in web CI: checkout backend at `openapi.lock.json` ref, `docker compose up`, run AT-03/06/09/11/12/13/14/22~~ **Deferred to post-MVP (D-068)**; C4 uses the manual smoke checklist (ACCEPTANCE_TESTS.md) | W-12, B-10 |
| Q-02 | `scripts/backup.sh`, `restore.sh`, `verify-restore.sh` + an integration test for AT-17 | B-10 |
| Q-03w | Web production image: multi-stage `Dockerfile` (Node build → Caddy), `Caddyfile` (SPA fallback, `/api/*` + `/readyz` proxy to `api:8080`, CSP and security headers, immutable caching for hashed assets), image built in `npm run check` (D-069) | W-00 |
| Q-03 | Parent `deploy/server/compose.yaml` (`./deploy/prod`) building both images on the server (D-069: no registry, native arch), host paths, prod backup/restore wiring, exposure check for the prod compose, deployment + upgrade README | B-10, Q-02, Q-03w |
| Q-04 | Fresh-clone verification (AT-01) by an agent following only the READMEs; fix the docs | Q-03 |
| Q-05 | Final review against AT-19 scope fence + security checklist (ARCHITECTURE §5) by a reviewer session | Q-04 |

**Checkpoint C4: the user accepts the MVP.**

## M6 — Architecture refactor (after the MVP and F-018, D-106)

Behaviour-preserving rebuild of the internals; briefs hold the stories: [F-019 backend](features/F-019-backend-architecture.md) (B0 spike, B1 baseline migration, B2 schema simplification, B3 features in layers, B4 lookup/integrations, B5 contract + docs) and [F-020 web](features/F-020-web-architecture.md) (W1 links in the web, W2 conventions and lint, W3 split big files, W4 data layer, W5 dev tooling, W6 adopt `api-v1.0.0`). The links move (F020-W1) comes first because it unblocks removing `store_links` / `platform_links` from the API.

**Checkpoint C5: the user accepts the cleaned-up services.**

## Parallel-safety rules

- At most one open PR touching `api/openapi.yaml` at a time, and at most one touching `db/migrations/`.
- Web feature work in M2 runs against MSW mocks generated from spec examples. Switching to the real API is just the Vite `/api` proxy (`API_PROXY_TARGET`, D-033) and needs no code change.
- If a web task finds a contract gap, it opens a backend task (with the orchestrator) instead of working around it in the client.
