# Decision Log

Format: `D-NNN | date | decision | rationale | alternatives`. Newest wins. Superseded entries are marked, not deleted.

## Open questions (need the user)

| ID | Question | Default if unanswered | Blocks |
|---|---|---|---|
| Q-4 | License for the private repos? | No LICENSE file (all rights reserved) until decided | Nothing |
| Q-6 | Visual direction: Inter + Fraunces, warm stone neutrals, teal accent. OK, or a different mood or accent? | As proposed | W-03 |

Answered 2026-10-13: Q-1 → D-026, Q-2 → D-027, Q-3 → D-028, Q-5 → D-029, Q-7 → D-030.

## Decisions

| ID | Date | Decision | Rationale | Alternatives |
|---|---|---|---|---|
| D-001 | 2026-10-13 | Two repos, `collections-app-backend` and `collections-app-frontend-web`. **No monorepo.** | Archive §12 (the later, more detailed decision). The archive's Part II row "One GitHub monorepo initially" and the "Monorepo layout" mention in §21 are **superseded** | Monorepo |
| D-002 | 2026-10-13 | Design docs live outside both repos at `/Users/federico/Developer/collections-app/design-docs/`, referenced from each CLAUDE.md by **absolute path** | User request. Absolute path because sessions may run in worktrees | Third repo; copy into repos |
| D-003 | 2026-10-13 | Markdown content and versions are stored **in Postgres** (`TEXT`), not on the filesystem | Atomic with metadata, no orphan reconciliation, simpler backups. It's also the better base for future Google-Docs-style real-time editing (CRDT updates and snapshots need transactional storage) | Filesystem immutable version files (archive §6) |
| D-004 | 2026-10-13 | Trash uses **batch cascade**: deleting stamps the root and all active descendants with one `trash_batch_id`, and restore reverts exactly that batch | Normal queries become `deleted_at IS NULL` with no recursive ancestor checks. Independently trashed children stay trashed | Ancestry-aware hiding (archive §10) |
| D-005 | 2026-10-13 | Frontend **vendors a pinned copy** of `openapi.yaml` (lock file with backend ref and sha256) and generates the client. CI checks for drift | No package registry or tokens to manage | Published npm client package |
| D-006 | 2026-10-13 | Item kind metadata is an `items.metadata JSONB` column, not a separate `item_metadata` table | It shares the item's version/ETag anyway, so one fewer join and one fewer table | Separate table (archive §13) |
| D-007 | 2026-10-13 | Image association is `items.image_attachment_id` (unique FK) plus `items.image_url`, with a CHECK making them mutually exclusive. `attachments` has no `item_id` | No circular FK. Exclusivity is enforced in the DB | `attachments.item_id` |
| D-008 | 2026-10-13 | A single `PUT /items/{id}/image` accepts either multipart upload or JSON `{url}` and replaces any existing image | Switching source is atomic in one request with one ETag | Separate URL field in PATCH plus a POST upload |
| D-009 | 2026-10-13 | Generate a JPEG thumbnail (longest side 640 px) on upload, used in lists and grids | Grid views would otherwise load up to 10 MB originals per card. Small scope addition | Originals only |
| D-010 | 2026-10-13 | Reorder endpoints need **no If-Match**. They send the full sibling ID set, and a set mismatch returns `409 order_stale` | Set equality already detects concurrent structural changes. Per-parent version counters add complexity | Parent "children version" ETag |
| D-011 | 2026-10-13 | `If-Match` values are typed (`"i-7"`, `"c-3"`, …), and `If-Match: *` is rejected | Prevents sending a content ETag to the metadata endpoint, and forces clients to state what they edited | Bare numbers |
| D-012 | 2026-10-13 | `GET /tree` returns all active folders and lists unpaginated. Folder and list `GET` collection endpoints are dropped | The sidebar needs the whole tree, and it's small | Paginated folder/list collections |
| D-013 | 2026-10-13 | Trash is addressed by batch ID (`/trash/{batch_id}`) | Maps 1:1 to Trash UI entries | `/trash/{type}/{id}` |
| D-014 | 2026-10-13 | Markdown is rendered **client-side** (react-markdown, no raw HTML, URL sanitizer). The backend stores source only | No HTML sanitizer needed server-side. The safe defaults are simpler | Server render + sanitize |
| D-015 | 2026-10-13 | Prices go over the wire as decimal strings | No float rounding | JSON numbers |
| D-016 | 2026-10-13 | Production is same-origin: the Caddy web container proxies `/api` to the backend. CORS is only for dev | Smaller attack surface, simpler config | Separate origins with CORS |
| D-017 | 2026-10-13 | Ports are published on `127.0.0.1` by default. Recommended remote access is Tailscale | Enforces "never expose an unauthenticated API" by default | LAN binding by default |
| D-018 | 2026-10-13 | Item list page size: default 50, **max 200** | Typical lists render in one request | Max 100 (archive) |
| D-019 | 2026-10-13 | Generated code (sqlc, server stubs, TS client) is **committed** and drift-checked in CI | Repos stay buildable without codegen tooling, and diffs are reviewable | Generate in CI only |
| D-020 | 2026-10-13 | The OpenAPI version (3.1 vs 3.0.3) is decided by R-2, based on server-codegen support (**resolved by D-041: 3.0.3**) | A generator-enforced contract beats 3.1 syntax | Force 3.1 |
| D-021 | 2026-10-13 | Model dispatch: research and tests → sonnet subagents; simple docs and codebase search → haiku; design, complex logic, and review → main session | User cost requirement | — |
| D-022 | 2026-10-13 | Branches are `feature/ fix/ hotfix/ refactor/ test/ docs/ chore/ ci/`, with Conventional Commits. `main` is protected and agents never push to it | User requirement | — |
| D-023 | 2026-10-13 | npm is the package manager | Fewer tools, and it's what the archive assumes | pnpm |
| D-024 | 2026-10-13 | Editor is CodeMirror 6 | Good Markdown source editing now, plus a Yjs binding (shared cursors) for future collaboration | Plain textarea |
| D-025 | 2026-10-13 | `GET/PATCH /api/v1/settings` covers workspace name and settings (one ETag). `GET /workspace` is dropped | One resource for one settings screen | Separate `/workspace` + `/workspace/settings` |
| D-026 | 2026-10-13 | ~~`design-docs/` is **not** versioned.~~ **Superseded by D-043.** It is a living planning workspace that agents update frequently (AGENT_WORKFLOW §7), with progress tracked in STATUS.md. It is not the services' documentation | User decision | git-tracked docs repo |
| D-027 | 2026-10-13 | The user reviews and merges every PR. Agents never merge unless explicitly told to for that PR | Default confirmed | — |
| D-028 | 2026-10-13 | MVP kinds are `generic`, `movie`, `tv_show`, `motorcycle`, `car`, `camera` (photo cameras). Field sets are in DATA_MODEL §2 (items) and PRODUCT §4.2. All kind fields are optional | User decision. Field lists proposed by the design session, open to tweaks | Movie only |
| D-029 | 2026-10-13 | GitHub account `0xfederama`, private repos `collections-app-backend` and `collections-app-frontend-web` (cloned as submodules `backend/` and `frontend-web/` under `/Users/federico/Developer/collections-app/`, D-043). They replace the placeholder names `collection-backend`/`collection-web` used in the archive. Images go to `ghcr.io/0xfederama/…` | User decision | — |
| D-030 | 2026-10-13 | Dark theme is **in the MVP**: it follows the system preference by default, with a per-device override (System/Light/Dark) stored in `localStorage` and set from Settings. Both themes must pass contrast and axe checks | User decision | Stretch goal |
| D-031 | 2026-10-13 | **No GitHub Actions or Dependabot for now.** All quality gates run locally: `make check` (backend) / `npm run check` (web) contain what ARCHITECTURE §6 listed for CI, where it works offline. Vulnerability scans are separate local targets (`make audit` / `npm run audit`). The session runs the gate before every PR and pastes the result under "How to verify". Tasks B-01 and W-01 are dropped, and later deps on them mean B-00/W-00. Supersedes the CI parts of ARCHITECTURE §6, AGENT_WORKFLOW §3/§6, and D-019 ("in CI" → "in the local check") | User decision: CI/CD later | GitHub Actions now |
| D-032 | 2026-10-13 | PRs exist so the user can **review the code**. No required approvals and no CI status checks. Agents still never push to `main` and never merge (D-027). Branch protection is optional (block direct pushes/force-push/deletion if the GitHub plan allows it on private repos) | User decision | Required approval + green CI |
| D-033 | 2026-10-13 | **Local run:** backend = one `docker compose up --build` (db + migrate + api, API on `127.0.0.1:8080` only). Web = `npm run dev` on the host (Vite :5173) with a **dev proxy `/api` → `http://localhost:8080`**, so dev is same-origin like prod: no CORS needed, `VITE_API_BASE_URL` is replaced by `API_PROXY_TARGET` (dev-server only), and the backend CORS middleware is dropped unless a later need appears. Web Dockerfile + Caddyfile move to Q-03, and the Playwright setup moves to Q-01 | User decision: "backend in one compose, frontend with something else". Proxy keeps dev = prod topology | CORS allowlist in dev; web in compose |
| D-034 | 2026-10-13 | **Lean frontend:** add a dependency only in the task that first uses it, and justify it in the PR. Pick the lighter option when quality is comparable, with no UI kits, icon mega-packs, or CSS-in-JS. Radix vs React Aria is chosen in R-1 by the user's criterion: **the leaner one that follows more up-to-date UI practices** (per-primitive install footprint, React-version support, release cadence, a11y quality, plain-CSS/Tailwind styling via data attributes). The session asks the user only if it's a close call | User decision: "clean and pretty UI, not bloated" | Install the full stack upfront |
| D-035 | 2026-10-13 | **Go tool pinning:** `govulncheck` (and later `sqlc`, `oapi-codegen`) via the `go.mod` `tool` directive (`go tool <name>`), so `go.sum` pins them. **golangci-lint** is pinned in the Makefile as `go run github.com/golangci/golangci-lint/v2/cmd/golangci-lint@v2.14.0`, because its docs say `go tool` is not recommended or guaranteed. The `migrate` CLI is used only through the pinned `migrate/migrate` Docker image | R-1. Pinned and reproducible without extra installs | `go run pkg@vX` for all; a separate tools module |
| D-036 | 2026-10-13 | **API runtime image:** `gcr.io/distroless/static-debian13:nonroot` with a static binary (`CGO_ENABLED=0`). The binary has a `healthcheck` subcommand that GETs `/readyz`, used by the compose healthcheck | R-1. Smallest image with no shell. pgx is pure Go | alpine runtime |
| D-037 | 2026-10-13 | **Empty migrations dir:** verified on 2026-10-13 that `migrate/migrate:v4.20.1 up` on a directory with only `.gitkeep` **exits 1** (`error: first .: file does not exist`). The compose `migrate` service therefore runs a small `sh` guard that exits 0 when `/migrations` has no `*.up.sql` file, and otherwise runs `migrate up`. B-02 (first real migration) may keep or drop the guard | Brief forbids a fake 000001 migration (it belongs to B-02) | A no-op migration |
| D-038 | 2026-10-13 | **Headless UI library: Radix UI, per-primitive `@radix-ui/react-*` packages** (installed in W-03, one primitive at a time per D-034). Researcher found Radix still active (release 2026-10-12) and the smallest per-primitive footprint (~100-190 KB each). Base UI 1.x was the closest alternative | User decision (the close-call question asked) | Base UI, React Aria Components |
| D-039 | 2026-10-13 | **Test DOM: jsdom.** It is the reference environment for Testing Library, and it is smaller on disk (5.5 MB vs 9.2 MB for happy-dom). Revisit only if suite speed becomes a measured problem | R-1 | happy-dom |
| D-040 | 2026-10-13 | **TypeScript 6.0.3** (not 7.x) because typescript-eslint 8.71.2 declares peer `typescript <6.1.0`. Move to 7 when typescript-eslint supports it | User decision | TypeScript 7.0.2 |
| D-041 | 2026-10-13 | **Contract tooling (resolves D-020):** OpenAPI **3.0.3**; server generation with **oapi-codegen v2 (strict server, chi)**; spec lint with **Redocly CLI** pinned and run via `npx` (no config needed, `recommended` ruleset). oapi-codegen's 3.1 support is only "initial" (v2.8.0, July 2026), and ogen has no official 3.1 claim. openapi-typescript and openapi-fetch work with 3.0.3. ETag/`If-Match` and problem+json handling are unverified for the generator, so B-03 prototypes one operation first | R-2 | ogen; spec 3.1; Spectral |
| D-042 | 2026-10-13 | **Web runtime baseline:** Node 24 LTS (`.nvmrc` 24, `engines` `>=24`). React Router 8 imports everything from `react-router` (`react-router-dom` is gone; DOM `RouterProvider` comes from `react-router/dom`). Node 26 becomes LTS on 2026-10-28, so revisit then | R-1 | Node 22, Node 26 |
| D-043 | 2026-10-14 | **Parent repo `0xfederama/collections-app`** (private) wraps the two service repos as **git submodules** with short local folders: `backend/` → `collections-app-backend`, `frontend-web/` → `collections-app-frontend-web`. GitHub repo names and remotes are unchanged. The parent tracks `design-docs/`, the whole-app `compose.yaml`, `.env.example`, `.gitignore` and README. D-001 (no monorepo, independent service repos) still holds; D-026 (docs not versioned) is superseded. Submodule pointers are bumped by the orchestrator after service PRs merge | User decision | Rename the GitHub repos; monorepo; sibling clones without a parent |

## Toolchain versions (R-1, checked 2026-10-13)

Sources: GitHub releases API, proxy.golang.org, go.dev, Docker Hub, npm registry, nodejs.org (fetched by researcher subagents, reviewed by the M0 session).

### Backend
| Tool | Version | Source |
|---|---|---|
| Go | 1.27.2 | https://go.dev/dl/?mode=json |
| PostgreSQL / image | 18.6 / `postgres:18.6-alpine3.24` | https://www.postgresql.org/support/versioning/ , https://hub.docker.com/_/postgres |
| chi | v5.4.0 | https://github.com/go-chi/chi/releases |
| pgx | v5.11.0 | https://github.com/jackc/pgx/releases |
| sqlc | v1.31.1 | https://github.com/sqlc-dev/sqlc/releases |
| golang-migrate (image) | v4.20.1 (`migrate/migrate:v4.20.1`) | https://github.com/golang-migrate/migrate/releases |
| golangci-lint | v2.14.0 (config `version: "2"`) | https://github.com/golangci/golangci-lint/releases |
| testcontainers-go (+ postgres module) | v0.44.0 | https://github.com/testcontainers/testcontainers-go/releases |
| golang.org/x/image | v0.47.0 | https://proxy.golang.org/golang.org/x/image/@latest |
| govulncheck (x/vuln) | v1.9.0 | https://proxy.golang.org/golang.org/x/vuln/@latest |
| oapi-codegen | v2.8.0 (B-03) | https://github.com/oapi-codegen/oapi-codegen/releases |
| Redocly CLI | 2.63.0 (B-03) | https://www.npmjs.com/package/@redocly/cli |
| Runtime image | `gcr.io/distroless/static-debian13:nonroot` | https://github.com/GoogleContainerTools/distroless |
| EXIF orientation | Not decided. The stdlib doesn't read orientation (unverified claim). Candidate `evanoberholster/imagemeta` v1.1.0 or a tiny own APP1 parser. The images task decides. `rwcarlsen/goexif` and `disintegration/imaging` are unmaintained | researcher report |

### Web
| Tool | Version | Source |
|---|---|---|
| Node / npm | 24.21.0 LTS / 11.19.0 | https://nodejs.org/dist/index.json |
| React / react-dom | 19.3.0 | https://registry.npmjs.org/react |
| Vite / @vitejs/plugin-react | 8.3.4 / 6.1.2 | https://registry.npmjs.org/vite |
| TypeScript | 6.0.3 (D-040) | https://registry.npmjs.org/typescript |
| react-router | 8.4.0 | https://registry.npmjs.org/react-router |
| Tailwind / @tailwindcss/vite | 4.3.3 (CSS-first) | https://registry.npmjs.org/tailwindcss |
| ESLint / @eslint/js | 10.12.0 / 10.0.1 | https://registry.npmjs.org/eslint |
| typescript-eslint | 8.71.2 | https://registry.npmjs.org/typescript-eslint |
| eslint-plugin-react-hooks | 7.1.1 | https://registry.npmjs.org/eslint-plugin-react-hooks |
| Prettier | 3.9.10 | https://registry.npmjs.org/prettier |
| Vitest | 5.0.4 | https://registry.npmjs.org/vitest |
| @testing-library/react / dom / jest-dom / user-event | 16.3.3 / 10.4.2 / 7.0.1 / 14.6.8 | https://registry.npmjs.org/@testing-library/react |
| jsdom | 30.1.2 | https://registry.npmjs.org/jsdom |
| Later tasks (not installed in W-00): @tanstack/react-query 5.104.2, msw 3.0.3, @playwright/test 1.64.0, @axe-core/playwright 4.13.0, codemirror 6.0.2, react-markdown 10.1.0, remark-gfm 4.0.1, openapi-typescript 7.13.0, openapi-fetch 0.17.0, @fontsource-variable/inter 5.3.0, @fontsource-variable/fraunces 5.3.0, caddy 2.11.7-alpine | | npm registry / Docker Hub |
| dnd-kit | Choice open for its task: legacy `@dnd-kit/core` 6.3.1 + `sortable` 10.0.0 (stable, frozen since Dec 2024) vs `@dnd-kit/react` 0.5.0 (active, pre-1.0) | https://registry.npmjs.org/@dnd-kit/react |


## Superseded points from the original archive

- "One GitHub monorepo initially" (Part II) and "Monorepo layout" (§21) are replaced by D-001.
- Filesystem Markdown storage and its write/reconcile flow (§6) are replaced by D-003.
- Ancestry-aware trash hiding (§10, §13) is replaced by D-004.
- The `item_metadata` table is replaced by D-006.
- The `/trash/{type}/{id}` endpoints are replaced by D-013, and `POST /items/{id}/image` by D-008.
- Paginated `GET /folders` and `GET /lists` are replaced by D-012.
