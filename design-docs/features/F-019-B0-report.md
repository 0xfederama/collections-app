# F019-B0 report: Huma spike (folders end to end)

Date: 2026-10-20. Branch `refactor/F019-B0-spike` (backend, commit `c813ba0`, local only, not pushed). Worker tier: the spike was written by the orchestrator itself (brief: "orchestrator tier for B0"), because its purpose is to find out what the tool does; all later code goes to simple-tier workers.

## Verdict
**Huma v2 (v2.39.1) is confirmed (F019-Q2).** Nothing blocks the principles. The slice built: `POST/GET/PATCH /folders`, `POST /folders/{id}/move`, `PUT /folders/order` in `internal/folders/{model,repository,service,handler}.go`, simple sqlc queries, a Go cycle check, workspace scope from the context, problem+json in one package. All ported AT-03/04/21 folder cases pass, including the concurrent-move test, with `-race`; 91.6% coverage; golangci-lint clean.

## What I built (and what it shows)
| Piece | Result |
|---|---|
| Layers | `handler.go` (Huma input/output structs, calls the service, `problem.From(err)`) → `service.go` (rules, tree lock, `Store`/`Repo` interfaces declared there) → `repository.go` (the only file with sqlc) |
| Queries | 11 one-table queries, no CTE. The recursive cycle CTE became `isSelfOrAncestor` in Go over `ListActive` (unit-tested without a DB, including a corrupt-cycle case). `ReorderFolders` (unnest) became N `SetSortOrder` updates inside the tx |
| Scope | `internal/platform/scope`: workspace id in the context; every repo method reads it. Adding accounts later changes this package |
| Errors | `internal/platform/problem`: one `Problem` type (implements `huma.StatusError`), `From(apperr)`, and an `Install()` that rewrites Huma's own validation errors into this API's shapes (unknown field 400, bad path/query 400, per-field 422) |
| Layer rules as lint | **golangci `depguard` with per-file rules works**: `**/handler.go` may not import pgx or sqlc; `**/service.go` may not import pgx, sqlc, huma or `net/http`; `**/repository.go` may not import huma or `net/http`. I verified a forbidden import in `service.go` is caught. This resolves "package by feature, but enforce layers" without sub-packages |
| Tests | handler tests (real HTTP through chi + real Postgres, ported from `tree_test.go`), service tests with a fake `Store` (no DB), pure-function tests. Ergonomics are good: the fake only implements what the test touches by embedding `Repo` |
| Tooling | Huma adds one dependency (plus a `klauspost/compress` bump). The spec is byte-identical across runs (properties sorted), so a drift check is reliable |

## Generated spec vs the web's current contract (folders)
The web's `openapi-typescript` 7.13 generates cleanly from the Huma 3.1 output (I compared the folder types only, not the whole web client). Files kept for review: `backend/docs/spike/folders-openapi-3.1.yaml` on the spike branch.
- `Folder`, `CreateFolderRequest`, `UpdateFolderRequest`, `MoveFolderRequest`, `ReorderFoldersRequest` keep their names (needs explicit named body types and a namer that strips a `JSON` suffix); fields, nullability and optionality are the same. Differences: properties are alphabetical, integers carry `Format: int64` comments, `ids` loses `format: uuid` on its items (fixable).
- `If-Match` is an optional header in the TS types, exactly as today.
- Gone, by design of the tool: the hand-written **examples** (the web's MSW `examples.ts` is generated from them; F-020 W5 already plans to drop it) and the reusable `components/responses` (every error is listed per operation as `Problem`).
- OpenAPI **3.1** is what Huma writes (`type: [string, "null"]`); openapi-typescript handles it, and a 3.0.3 downgrade also works if ever needed.

## Behaviour differences found (all are guard rails for B3, with characterization tests)
1. Wrong `Content-Type`: Huma answers **415** (old: 400 `malformed_request`) and its detail **echoes the request body**: must be replaced. A missing Content-Type is accepted as JSON (old: 400).
2. Order of checks: a missing `If-Match` with an invalid body gives 422 (old: 428 first). To keep the old order, the check moves into an operation middleware; I recommend keeping the handler check and accepting this edge unless a test pins it.
3. Router 404/405 are chi's; the existing `NotFound`/`MethodNotAllowed` problem handlers move into `platform/httpserver` unchanged.
4. Timestamps from Postgres come back in the local zone; the mapper must call `.UTC()` (done in the spike).
5. Nil slices become `type: [array, null]` unless the field has `nullable:"false"` (done for `ids`).
6. Huma's defaults to switch off: `$schema` links, docs and spec routes (done). One unavoidable global: `huma.NewError` is a package variable, set once in `problem.Install()`.
7. The old spec documents error **codes** per status; Huma lists statuses only. The "one error-code list in the spec" principle needs a hand-built `Problem.code` enum/description (small, in `problem`).
8. Existing middleware (request id, security headers, access log, recoverer, body-size guard) is not yet ported; Huma has per-operation `MaxBodyBytes` (413 verified at 64 KiB) so `guard.go` is replaced by Huma validation + a smaller middleware.

## Baseline migration feasibility (for B1)
Ran the 25 migrations in Postgres 18.6 and `pg_dump --schema-only`: 844 lines, 11 tables, **1 trigger, 3 PL/pgSQL functions** (the seeding), 13 `ON DELETE CASCADE`. Re-applying a cleaned copy of the dump into an empty database and dumping again gives an identical dump **except one cosmetic parenthesisation in `lookup_imports_source_id_check`** (Postgres normalises the expression differently on re-apply). So the equality proof is: dump(old chain) vs dump(baseline), with that constraint compared in its re-applied form; the draft is `docs/spike/baseline-draft-pgdump.sql` (not final: B1 hand-organises it, B2 then removes the trigger/functions/cascades).

## Changes to the brief's defaults (to confirm; DECISIONS via the top-level orchestrator)
1. **Huma v2** confirmed; OpenAPI 3.1 is the committed contract; `make spec` (a small `cmd/specgen`) + `make check-spec` drift.
2. **Layer enforcement = depguard per-file rules** (above), plus a package-level import test for cross-feature imports (features may not import each other's repository/handler; only `service` types through consumer interfaces).
3. **Layout addition:** `internal/platform/{scope,problem,httpserver,database}`; sqlc output stays **one shared package** (`internal/platform/database/sqlc`, `db/queries/<feature>.sql`). The spike generated a package per feature and each got a 166-line `models.go` of every table, which does not scale; repositories alone import the shared package (depguard).
4. **Which features get a service** (rule: only where there are rules): folders (tree lock, cycle, order), lists, definitions, items, content, images, trash, search (ordering/paths), lookup, workspace/settings (version + cascading clears). Plain reads like `GET /tree` and `GET /settings` read through the consumer interface from the handler. Final list recorded at each B3 PR.
5. Reorder uses N single-row updates instead of one `unnest` statement (simplicity over one round trip; single user, tens of rows).
6. The old `tree` package splits into `folders` and `lists`; `GET /tree` becomes a small `tree` read-only feature that composes the two repositories' list methods.

## Proposed PR plan (task specs follow after your OK)
B1 baseline (+ deletion of migration-history tests, `strip-images`, link backfill; backup/deploy script adaptation) → B2 schema simplification → B3a platform+workspace → B3b folders+lists+tree (the spike code is kept as the first slice) → B3c types and fields → B3d items+content → B3e images → B3f trash+search → B4 lookup/integrations (link builders removed once web F020-W1 is merged) → B6 log viewer → B5 contract+docs+final review and tags. Each PR is cut into worker tasks of at most ~300 changed lines, each starting with characterization tests; every B3 PR ends with `make check`, the others as the workflow table says.

## Open points for you
- Is a stack (Huma + chi) that keeps `chi` for the platform OK, and are 415/428-order differences acceptable as listed (1 and 2)?
- B0 is committed locally on `refactor/F019-B0-spike`; it is not pushed or merged. I would open it as the first B3b slice rather than discard it.
- The dev database will be recreated at B1 (you will be told before it happens).
