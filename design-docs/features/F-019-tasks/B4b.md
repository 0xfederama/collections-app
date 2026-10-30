# F019-B4b task specs: lookup and integrations (PR 10)

Branch `refactor/F019-B4b-lookup`, worktree `/Users/federico/Developer/collections-app/backend-F019-B4b`. Rules/patterns as B3a..f.md. Keep: TMDB retention rules (D-089), book source rules (D-102), Open Library primary + Hardcover gap filler, fixtures (no network in tests). Safety net unchanged: `internal/lookup/*_test.go`, `internal/httpapi/{tmdb,books_lookup,book,items}_test.go`, `internal/tmdb|openlibrary|hardcover` tests.

## T1 · integrations move (mechanical)
`git mv internal/tmdb internal/integrations/tmdb`, same for openlibrary and hardcover; fix imports/docs paths (Makefile, Dockerfile, scripts, CLAUDE.md is the orchestrator's); testdata paths in tests. No logic change.

## T2a · pure rules out of store.go
Move the pure helpers of `lookup/store.go` into `merge.go` (mergeMetadata, fillOnly, mergeTitle, removeUnchangedOwned, snapshotPresent, validateApply, cleanLookupTitle/Website) and `paths.go` (flatten, getPath, setPath, deletePath, cloneLookupMap, equalValue, normalizeValue, sameJSON ...), with their tests moved alongside (names kept). `store.go` keeps only DB code. No behaviour change; `go test ./internal/lookup/` unchanged.

## T2b · repository, apply and retention over it
`lookup/repository.go` (Postgres, InTx, Repo; workspace from ctx): one plain method per query of `db/queries/lookup_imports.sql` (+ the type/field/price reads lookup does today inside its tx: SEAM `// SEAM: moves to definitions`); `apply.go` (`DBStore.Apply` logic over the Repo: lock, recheck, merge, write item through the repo, attachment insert, provenance upsert; files before tx / old files after commit as today; poster handling), `retention.go` (Maintain, Run, expireOne over the Repo; D-089 rules). Delete `DBStore` code that talked to sqlc directly. Same errors/ordering; fake-Repo tests for apply paths (create, fill, refresh, owned-field preservation) + the existing integration tests unchanged.

## T3 · handlers on Huma, retire the rest of the old server
Huma ops for the lookup routes: `listTmdbSuggestions`, the book suggestions op, `lookupItemMetadata` (If-Match "i-N"), and `GET /store-providers` (httpapi/stores.go) — read `httpapi/{tmdb,books,stores}.go` and `items.go LookupItemMetadata`, the spec schemas, and keep responses identical (disabled => `{available:false, results:[]}`, 503 problems for upstream failures). Delete those handlers and their guard entries; remove `lookup` from the archtest allowlist and fix layer findings; delete unused queries; `make generate`. After this the legacy `httpapi.Server` only serves `/healthz` and `/readyz`.
