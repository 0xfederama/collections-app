# F-019 — Backend architecture refactor ("as if we had just started")

Status: **done** (2026-10-31; backend#51-#65, `api-v1.0.0`/`api-v1.0.1`, `v2.6.0`; see D-108)    Release: backend 2.6.0 (see F019-Q1)    Roadmap: ROADMAP.md §6
Repos: backend (parent: docs)    Contract: `api-v1.0.0`    Companion: [F-020](F-020-web-architecture.md) (web)

## Why
The backend grew feature by feature: 25 migrations with one-off backfills, SQL triggers and PL/pgSQL functions, a spec-first OpenAPI file with a 11k-line generated server, services that mix business rules, SQL and HTTP details, and URL builders for stores and streaming. Production is not in use and no backward compatibility is needed, so this is the moment to rebuild the internals to a standard worth showing: **someone opening the repo should think "this is clean"**.

## Principles (the acceptance bar)
1. **Layers with one direction:** `handler` (controller: HTTP in, HTTP out, nothing else) → `service` (business rules, transactions, no SQL, no HTTP types) → `repository` (the DAO: the only place that knows SQL) → database. Each feature owns its handler, service, repository and model in one package, behind small interfaces defined where they are used. **Idiomatic Go, not Spring in Go:** package by feature (no `controllers/` or `services/` folders), interfaces declared by the consumer and kept small (no interface per struct, no `Impl`), plain constructor wiring in `cmd/api` (no DI container or reflection). **A service exists only where there are real rules** (validation across fields, transactions, ordering, lookups, trash); for plain CRUD the handler calls the repository through a small interface, and no empty pass-through layer is created. The orchestrator records which features have a service and why. Shared plumbing lives in `internal/platform` (config, database, HTTP server, logging, problem details, ETag).
2. **Simple queries, simple mappers.** Each repository method runs one plain query on one table (or one obvious join). **No CTE gymnastics, no window tricks, no JSON assembly in SQL, no triggers, no PL/pgSQL functions.** Anything smarter than that is Go code in the service, where it can be read, tested and debugged. Queries stay in `.sql` files with sqlc (type-safe, explicit), mapped to domain models by small mappers.
3. **Avoid deletes.** Data is archived, not removed: soft-delete columns (`deleted_at`) and the existing trash batches; no `ON DELETE CASCADE` doing business logic behind the code's back. The only hard deletes are the explicit purge operations (empty trash, auto-purge), written as one clearly named service function each.
4. **One database spec.** The 25 migrations become a single baseline **`000001_init`** (schema, constraints, indexes, and no seed logic in SQL). The built-in types are seeded from Go at startup and at workspace creation, idempotently. Old per-migration tests, one-off backfills (`strip-images`, link backfill, retention one-offs that are no longer needed) and their commands are deleted. Future changes append normal migrations after the baseline.
5. **Code-first OpenAPI.** The spec is **generated from the handler code**, not hand-written, and committed as a generated artefact checked by a drift check. Recommended: **Huma v2** (typed operations, OpenAPI 3.1, validation from struct tags) on the chi router. The first task is a one-resource spike to confirm it; the orchestrator may pick another code-first approach only with a written reason. Operation ids and schema names are kept stable where possible, so the web contract diff stays small.
6. **Current practice, small surface:** Go 1.27, `log/slog`, context everywhere, errors wrapped with `%w` and mapped to RFC 9457 problems in one place, no package-level state, graceful shutdown, config from the environment in one struct, `go tool` directives (or pinned tools) for sqlc/linters, golangci-lint v2 config in the repo, table-driven tests, `t.Parallel()` where safe. Files stay small (a file over about 300 lines needs a reason). Names say what things are; comments say why.
7. **Behaviour is preserved.** The refactor changes how the code is built, not what the API does, except the explicit contract changes listed here. The existing test suites, `make smoke`, `make test-backup` and the web e2e (50 specs) are the safety net and are not weakened.

## Target layout (default, the orchestrator may refine and records why)
```
cmd/api/                 entry point: wiring only
internal/platform/       config, database (pool, tx helper), httpserver, problem, etag, logging
internal/<feature>/      handler.go  service.go  repository.go  model.go  (+ _test files)
                         features: workspace, tree (folders, lists), types (definitions), items, content, images, trash, search
internal/lookup/         provider interface + service; providers in internal/integrations/{tmdb,openlibrary,hardcover}
db/migrations/           000001_init (baseline)      db/queries/  one .sql file per feature
api/openapi.yaml         GENERATED (make spec), never edited by hand
```

## Contract changes (the only ones allowed)
- The spec is generated; schema and operation names stay as stable as the tool allows. A diff report old vs new is part of the PR.
- **Links leave the backend:** `store_links` and `platform_links` (and the Amazon country table, store URL building and streaming search URLs behind them) are removed. The API returns data (`isbn`, title, streaming platforms and country, TMDB's own `streaming.link`), and the web builds URLs. See F-020-W1. Removed only after the web no longer reads them.
- Anything else found worth changing (naming inconsistencies, redundant fields) is allowed if listed in the report with a reason; **the user does not care about compatibility, only about the result being clean and the web being adapted in the same round**.
- Tag `api-v1.0.0` marks the first stable contract.

## User stories
- **F019-B0 · Spike and decisions.** Implement one resource end to end (suggested: folders) in the target style with Huma, generated spec, simple queries and the baseline migration. Report: spec quality (OpenAPI 3.1 vs the web's `openapi-typescript`/`openapi-fetch`), validation behaviour (unknown fields, limits, If-Match/ETag, problem+json), test ergonomics, and anything that blocks the principles. Confirm or change the defaults of this brief, and write them as DECISIONS entries via the top-level orchestrator.
- **F019-B1 · Baseline and cleanup.** Squash the migrations into `000001_init` that produces the same final schema (prove it: `pg_dump --schema-only` of the old chain and the new baseline match apart from ordering), delete the migration-history tests, one-off backfills and the `strip-images` / backfill code paths, adapt `make test-backup` and the deploy scripts. Dev databases are recreated (`./deploy/dev` data may be reset; the user is told before it happens).
- **F019-B2 · Schema simplification.** Remove triggers and PL/pgSQL (seeding moves to Go), make deletion columns consistent (`deleted_at`, trash batch id), drop cascades that hide behaviour, keep integrity constraints (FKs, unique, checks). Schema notes go to DATA_MODEL via the top-level orchestrator.
- **F019-B3 · Features in layers.** Rebuild each feature in the target layout, one PR per group, in this order: platform + workspace/settings → tree (folders, lists) → types and fields (definitions) → items + content → images → trash + search. Each PR leaves `main` green, deletes the code it replaces, and has no SQL outside repositories and no HTTP types outside handlers (enforce with an import-boundary lint or a test).
- **F019-B4 · Lookup and integrations.** One provider interface for movies, TV and books; TMDB, Open Library and Hardcover behind it; the TMDB retention rules (D-089) and the book source rules (D-102) are kept, simplified, and covered by tests with fakes. Remove the link builders once F020-W1 is merged.
- **F019-B6 · Log viewer.** As described under Additional scope; small, with a test for the ring buffer, the redaction and the off-by-default switch. May be done after B3.
- **F019-B5 · Contract, docs, polish.** Generated spec committed, `make spec` and `make check-spec` (drift) in `make check`; `api-v1.0.0` tagged; `backend/docs/modules`, `README` and `CLAUDE.md` rewritten to the new structure (docs-keeper); a final clean-up pass by a fresh reviewer session (`/code-review` at medium effort and `/simplify`) with the findings fixed; `make check`, `make test-backup`, `make smoke`, `make audit` green.

## PR plan
Several PRs, because one rewrite PR would be unreviewable. Suggested split: B0 (spike, may be discarded or kept as the first slice) · B1 · B2 · B3 (up to six PRs) · B4 · B5. Each is squash-merged by the orchestrator after the gate and leaves the API working for the current web, **except** the contract-changing PR (B5 and the link removal), which is merged together with the web adoption in F-020. Tags: only `api-v1.0.0` and the final release.


## Execution model (user decision 2026-10-21, overrides the D-087 tier choice for this refactor)
- **All code is written by simple-tier workers (Haiku 5.5 or GPT 6 Luna, medium)**, even for the complex tasks. The orchestrator tier plans, reviews and runs the gates. Escalate a task to the complex tier only after a simple worker has failed it twice, and say so in the Repo breakdown.
- **So the plan must be expanded by the repo orchestrator into task specs.** This brief fixes the design and the order; it does not say which files change. Before dispatching, the orchestrator writes one spec per task (kept in the Repo breakdown or a `tasks/` note in the PR): the files to create, change or delete; the target type and function signatures; the exact tests that must pass (and which existing tests must stay green); what the worker must not touch; the layer rules to respect. A task is small enough to be reviewed as one diff (about 300 changed lines at most, one seam at a time).
- **Characterization first.** Before a seam is rebuilt, a task adds tests that pin its current behaviour (HTTP-level for the backend, component or e2e level for the web). Workers then rebuild until those tests pass unchanged. This is what makes a small model safe on a big refactor.
- **Machine checks beat review.** The layer and import rules are enforced by lint or a test (backend `depguard`-style rules or an import test; web boundary lint), so a worker cannot quietly break the architecture; the orchestrator reviews the FLAGS and the diff of the risky parts only.

## Additional scope (added 2026-10-21)
- **Ready for accounts without building them:** every repository method takes the workspace scope from the request context through one small `scope` helper, so adding users and permissions later (pool 7) touches one place, not every query. No behaviour change today.
- **Consistent API shape:** one pagination style, one error-code list (documented in the spec), uniform `version` / ETag handling, consistent field naming, and no unused endpoint or field left in the spec.
- **Lint and tools as code:** `golangci-lint` v2 config in the repo with the boundary rules, `go tool` directives for sqlc and the spec generator, `govulncheck` in `make audit`, a dead-code check (`deadcode`) in the final pass.
- **Fast, reliable tests:** repository tests on a real Postgres (one container per package, parallel tests), service tests with fakes, handler tests on the generated router; per-package coverage printed (no threshold, D-034); no test depends on another's data.
- **A log viewer served by the backend (F019-B6).** The backend keeps the last N log records (default 2000) in an in-memory ring buffer fed by a `slog` handler that sits next to the normal JSON output, and serves them itself: `GET /admin/logs` (JSON; filters `level`, `since`, `limit`) and `GET /admin/logs/view`, one self-contained HTML page embedded with `go:embed` (plain HTML, CSS and a few dozen lines of JS: level filter, text filter, auto-refresh), **nothing in `frontend-web/`**. Rules: off by default in production and enabled with `LOGS_UI=true` (on in dev and test); not part of the public OpenAPI spec; bound to the same loopback/tailnet address as the app, since there is no auth yet (the security review, pool 8, decides its exposure); the handler never logs request or response bodies, keys or tokens, and the buffer redacts known secret fields. History beyond the buffer stays in `docker logs`. No metrics, tracing, rate limiting or auth.
- **Docs that match:** README quick start, one architecture page with a diagram of the layers, and `docs/modules` regenerated from the new structure; `CLAUDE.md` / `AGENTS.md` keep one source of truth (one imports or links the other) instead of two copies.

## Constraints
- Lean workflow D-079/D-081, AI-agnostic tiers (D-087): orchestrator tier for B0 and the review passes; see Execution model: simple-tier workers for all code (D-107).
- Tests never call real networks; the TMDB/book fixtures of D-090 stay.
- No new runtime dependency without a line in the PR saying why (Huma is the expected exception).

## Out of scope
Accounts and permissions (pool item 7), collaborative Markdown, new features, UI changes, deployment changes.

## Open questions
| ID | Question | Default |
|---|---|---|
| F019-Q1 | Version of the release | backend 2.6.0, contract `api-v1.0.0` (minor despite the break, as before); a 3.0.0 would push accounts to 4.0 |
| F019-Q2 | Huma or another code-first tool | Huma v2, confirmed or changed by B0 |
| F019-Q3 | Hard deletes anywhere besides purge | No |

## Repo breakdown (filled by the repo orchestrator)
- **F019-B0 done 2026-10-20** (orchestrator-tier spike, no worker): Huma v2 confirmed, depguard per-file layer rules proven, baseline feasible. Report and proposed changes to the defaults: [F-019-B0-report.md](F-019-B0-report.md). Task specs for B1+ are written after the user confirms the report.

## Log
- 2026-10-21: planned from the user's request.
