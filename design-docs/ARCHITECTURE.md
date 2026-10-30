# Architecture

> **Versions:** this document names tools, not versions. Task M0-R1 (IMPLEMENTATION_PLAN) has the `researcher`
> agent verify current stable versions and maintenance status, and record them in DECISIONS.md and each repo's
> CLAUDE.md. Never take versions from memory or from old examples.

> **Since F-019 (D-108)** the backend is built in layers: per feature `handler.go` (Huma operations) → `service.go` (rules, no SQL, no HTTP) → `repository.go` (the only file that runs sqlc queries), with `internal/platform/*` for plumbing and `internal/integrations/*` for TMDB, Open Library and Hardcover; layer rules are enforced by `.golangci.yml` depguard and an architecture test. The OpenAPI spec is **generated from the handlers** (Huma, OpenAPI 3.1). The authoritative, current description is `backend/docs/architecture.md`; where this document differs on backend internals (sections below were written for the MVP), that page wins. The web follows feature slices with lint-enforced boundaries (`frontend-web/docs`, F-020).

## 1. System overview

```text
 Browser ──► collections-app-frontend-web (static SPA)
               │  dev:  Vite :5173 proxies /api → API :8080 (same origin, D-033)
               │  prod: Caddy serves SPA and reverse-proxies /api → same origin, no CORS
               ▼
            collections-app-backend (Go, :8080)
               ├── PostgreSQL (internal Docker network only)
               │     all relational data + Markdown content/versions
               └── DATA_DIR (persistent volume)
                     images/ originals + thumbnails
```

There are two service repositories and no monorepo, wrapped by a parent `collections-app` repo that holds them as git submodules (`backend/`, `frontend-web/`) plus docs and the whole-app compose (D-043). Local folder names below are `backend/` and `frontend-web/`. The backend never depends on web sources, and the web app never depends on Go internals.

## 2. Backend (`collections-app-backend`)

### Stack
Go (current stable) · `net/http` and `chi` · PostgreSQL (current stable, with the `pg_trgm` extension) · `pgx/v5` ·
`sqlc` · `golang-migrate` · `log/slog` · `golang.org/x/image` (WebP decode, resizing) ·
tests with `go test`, `testcontainers-go` (real Postgres), and `golangci-lint`.

### API implementation approach: spec-first
`api/openapi.yaml` is written first, then server interfaces and types are **generated** from it, so the code
cannot drift from the contract. **Decision gate M0-R2:** the researcher compares `oapi-codegen` (strict chi server) and
`ogen` for current OpenAPI 3.1 support. If the best-maintained generator needs 3.0.x, write the spec in 3.0.3. A
generator-enforced contract is worth more than 3.1 syntax. Whichever is chosen, CI also validates the spec with a linter
(e.g. Redocly CLI or Spectral) and checks that generated code is up to date.

### Layout

```text
collections-app-backend/
├── cmd/api/main.go             # wiring only: config → db → services → http server
├── internal/
│   ├── config/                 # env parsing + validation (fail fast)
│   ├── database/               # pgx pool, tx helper, sqlc generated code in database/sqlc
│   ├── httpapi/                # generated server iface, handlers, middleware, problem+json, ETag helpers
│   ├── workspace/              # bootstrap, settings
│   ├── tree/                   # folders + lists: CRUD, move, reorder, cycle checks
│   ├── items/                  # items CRUD, move, reorder, definition-backed metadata validation
│   ├── definitions/            # workspace kind/field definitions and their optimistic-concurrency writes
│   ├── content/                # markdown versions, retention, restore
│   ├── images/                 # upload validation, thumbnails, attach/replace/remove
│   ├── trash/                  # batches, restore, purge
│   ├── search/
│   └── storage/                # FileStore interface + local filesystem impl + orphan sweeper
├── db/migrations/              # golang-migrate NNNNNN_name.{up,down}.sql
├── db/queries/                 # sqlc .sql per domain
├── api/openapi.yaml            # canonical contract
├── scripts/                    # backup.sh, restore.sh, verify-restore.sh, dev helpers
├── deploy/                     # local + server compose files, wrappers (D-073)
├── docs/                       # minimal module docs (AGENT_WORKFLOW §5)
├── .claude/agents/             # researcher, test-writer, docs-keeper
├── compose.yaml                # local dev: postgres + migrate + api
├── Dockerfile  Makefile  sqlc.yaml  .env.example  CLAUDE.md  README.md
```

### Rules
- **Layering:** `httpapi` (decode, validate shape, map errors) → domain service (business rules, transactions) → sqlc queries / `storage`. Handlers contain no SQL, and services don't know about HTTP.
- **Errors:** domain packages return typed errors (`ErrNotFound`, `ErrVersionConflict`, `ErrCycle`, `ErrParentInTrash`, …). `httpapi` alone maps them to problem+json (API §4).
- **Transactions:** one helper `database.InTx(ctx, func(q *sqlc.Queries) error)`. Every multi-statement write runs in a transaction.
- **Workspace scoping:** every query filters by `workspace_id`. The single workspace ID is resolved at startup and injected. This is the Phase 3 seam.
- **Time:** an injected `Clock` for testability. All timestamps are UTC `TIMESTAMPTZ`.
- **Config:** environment variables only, validated at startup. See BACKUP_AND_DEPLOYMENT §3.
- **HTTP server:** read/write/idle timeouts, max header size, per-route body limits, graceful shutdown on SIGTERM, `/healthz` (liveness) and `/readyz` (DB ping, data dir writable).
- **Middleware:** request ID, structured access log (no bodies), panic recovery → 500 problem, security headers (no CORS, D-033) (`X-Content-Type-Options: nosniff`, `Referrer-Policy: no-referrer`, …).
- **Migrations** run as a separate step (`make migrate` / Compose `migrate` service), not implicitly inside the API process.
- **No** ORM, DI framework, global mutable state, or `init()` side effects.

## 3. Frontend (`collections-app-frontend-web`)

### Stack (finalize versions in M0-R1)
React · TypeScript (strict) · Vite · npm with a committed `package-lock.json` ·
API types and client via **openapi-typescript + openapi-fetch** (thin, typed, maintained; verify in M0-R1) ·
server state via **TanStack Query** · routing via **React Router** (data router, needed for `useBlocker` unsaved-changes guard) ·
styling with **Tailwind CSS** using design tokens as CSS variables, plus accessible headless primitives (**Radix UI** or **React Aria Components**, pick one in M0-R1) ·
drag-and-drop via **dnd-kit** (keyboard sensor) · Markdown editor **CodeMirror 6** (it has a Yjs binding for future real-time collaboration) ·
Markdown rendering with **react-markdown + remark-gfm**, raw HTML disabled, plus a URL sanitizer ·
self-hosted fonts via **Fontsource** (no third-party font CDN) ·
tests: **Vitest + Testing Library + MSW**, e2e with **Playwright** and **@axe-core/playwright** ·
lint/format: ESLint (flat config, typescript-eslint) + Prettier.

### Layout

```text
collections-app-frontend-web/
├── api/openapi.yaml, api/openapi.lock.json   # vendored pinned contract
├── src/
│   ├── app/          # providers, router, query client, error boundary
│   ├── components/ui/# design system primitives (Button, Dialog, Menu, Field, Card, Toast, Skeleton…)
│   ├── features/     # tree, lists, items, content, images, search, trash, settings, conflicts
│   ├── layouts/      # AppShell (sidebar/drawer + main + detail panel)
│   ├── lib/          # api client wrapper (ETag/If-Match, problem parsing), links, format, sanitize
│   ├── routes/
│   ├── styles/       # tokens.css, global.css
│   └── generated/    # openapi-typescript output (committed, drift-checked)
├── tests/e2e/        # Playwright (runs against real backend, see IMPLEMENTATION_PLAN Q-tasks)
├── scripts/api-sync.mjs
├── docs/  .claude/agents/  Dockerfile (build → Caddy)  Caddyfile  CLAUDE.md  README.md
```

### Rules
- All server data goes through TanStack Query hooks in `features/*/api.ts`. No ad-hoc `fetch`.
- `lib/api` adds `If-Match: "<etag>"` from the resource's `version` field (API §3) and turns problem+json into a typed `ApiError` with a `code`.
- Drafts live in component state while editing. A version conflict or network error **never** discards them.
- Optimistic updates only for reorder (with rollback). Everything else waits for the server.
- Generated code is never hand-edited.

## 4. Storage architecture

| Data | Where | Why |
|---|---|---|
| Hierarchy, items, metadata, settings, trash | Postgres | Relational integrity |
| Markdown content and all retained versions | **Postgres** (`TEXT`) | Atomic with metadata; no orphan reconciliation; simple backup; the right base for future CRDT storage (§7) |
| Image originals and thumbnails | Filesystem under `DATA_DIR/images/`, metadata in Postgres | Binary blobs up to 10 MB stay out of the DB |

Image file-and-DB consistency: files are written **before** the DB transaction that references them, and deleted **after**
the transaction that unreferences them commits. A crash leaves orphan files at worst, never dangling references.
The orphan sweeper (at startup and every 24 h) deletes files under `images/` that have no `attachments` row and are older than 1 h,
and deletes `attachments` rows not referenced by any item and older than 1 h (plus their files).

## 5. Security

- Never publicly exposed without auth (PRODUCT §7). Compose binds `127.0.0.1` by default.
- Upload validation: magic-byte sniffing (JPEG/PNG/WebP only), `image.DecodeConfig` dimension cap (≤ 40 MP) before full decode (decompression-bomb guard), 10 MiB limit via `http.MaxBytesReader`, generated storage keys, original filename kept for display only.
- Served files: `Content-Type` from DB, `nosniff`, `Content-Disposition: inline`, CSP `default-src 'none'` on file responses.
- URLs (official site, image URL, IMDb) are validated to http/https. The frontend sanitizes Markdown link and image URLs too.
- The SPA sets a strict CSP via Caddy in prod. External images are allowed via `img-src https: data: blob:`.
- No secrets in the repo. `.env.example` uses placeholders. `govulncheck` / `npm audit` (or equivalent chosen in M0-R1) run locally via `make audit` / `npm run audit` (D-031).

## 6. CI (GitHub Actions, per repo)

> **2026-10-13, D-031/D-033:** no GitHub Actions or Dependabot for now. The checks below run **locally** through
> `make check` / `npm run check` (vuln scans via `make audit` / `npm run audit`). Playwright e2e arrives with Q-01. The last line
> about branch protection is replaced by D-032. Rows whose files don't exist yet are added to the check by the task that creates them.

| Backend | Web |
|---|---|
| gofmt/goimports check, golangci-lint | Prettier check, ESLint |
| `go test ./...` with testcontainers Postgres | `tsc --noEmit` |
| migrations up → down → up on fresh Postgres | Vitest |
| sqlc generate + `git diff --exit-code` | `npm run api:check` (lock hash + generated drift) |
| OpenAPI lint + generated server code drift | `vite build` |
| govulncheck, Docker build | Playwright e2e against backend at pinned ref (nightly + on PRs touching src) |

Both repos: Dependabot (gomod/npm, github-actions, docker), branch protection on `main` requiring CI and one approval (the user).

## 7. Extension points (allowed seams, no speculative code)

| Future | Seam kept now |
|---|---|
| Accounts (Phase 3) | `workspace_id` on every table and query; single resolution point for "current workspace" in middleware |
| TMDB (Phase 2) | Definition-backed metadata validation by stable field key; metadata JSONB; no provider columns yet |
| Real-time collaborative Markdown | Content in Postgres with per-item versions; CodeMirror 6 editor. Later: add `item_content_updates(item_id, seq, update BYTEA)` + snapshot table for Yjs updates, a WebSocket endpoint, and `y-codemirror.next`. Saved versions remain checkpoints |
| Multiple images | `attachments` table independent of `items`; adding `item_attachments` later is additive |
| Mobile app | Same pinned OpenAPI contract; separate repo |
