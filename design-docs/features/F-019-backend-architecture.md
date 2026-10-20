# F-019 — Backend architecture refactor ("as if we had just started")

Status: **planned** (2026-10-21, from the user's request; defaults below to confirm in the first report)    Release: backend 2.6.0 (see F019-Q1)    Roadmap: ROADMAP.md §6
Repos: backend (parent: docs)    Contract: `api-v1.0.0`    Companion: [F-020](F-020-web-architecture.md) (web)

## Why
The backend grew feature by feature: 25 migrations with one-off backfills, SQL triggers and PL/pgSQL functions, a spec-first OpenAPI file with a 11k-line generated server, services that mix business rules, SQL and HTTP details, and URL builders for stores and streaming. Production is not in use and no backward compatibility is needed, so this is the moment to rebuild the internals to a standard worth showing: **someone opening the repo should think "this is clean"**.

## Principles (the acceptance bar)
1. **Layers with one direction:** `handler` (controller: HTTP in, HTTP out, nothing else) → `service` (business rules, transactions, no SQL, no HTTP types) → `repository` (the DAO: the only place that knows SQL) → database. Each feature owns its handler, service, repository and model in one package, behind small interfaces defined where they are used. Shared plumbing lives in `internal/platform` (config, database, HTTP server, logging, problem details, ETag).
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
- **F019-B5 · Contract, docs, polish.** Generated spec committed, `make spec` and `make check-spec` (drift) in `make check`; `api-v1.0.0` tagged; `backend/docs/modules`, `README` and `CLAUDE.md` rewritten to the new structure (docs-keeper); a final clean-up pass by a fresh reviewer session (`/code-review` at high effort and `/simplify`) with the findings fixed; `make check`, `make test-backup`, `make smoke`, `make audit` green.

## PR plan
Several PRs, because one rewrite PR would be unreviewable. Suggested split: B0 (spike, may be discarded or kept as the first slice) · B1 · B2 · B3 (up to six PRs) · B4 · B5. Each is squash-merged by the orchestrator after the gate and leaves the API working for the current web, **except** the contract-changing PR (B5 and the link removal), which is merged together with the web adoption in F-020. Tags: only `api-v1.0.0` and the final release.

## Constraints
- Lean workflow D-079/D-081, AI-agnostic tiers (D-087): orchestrator tier for B0 and the review passes; complex worker tier for B1, B2, B3 and B4; simple tier for docs, mechanical moves and tests.
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

## Log
- 2026-10-21: planned from the user's request.
