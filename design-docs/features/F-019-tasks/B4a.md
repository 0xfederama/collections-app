# F019-B4a task specs: link builders leave the backend (PR 6, done before B3d)

Why now: F020-W1 is merged (web#81): the web builds store and streaming links itself and no longer reads `store_links` / `platform_links` (only tests assert it ignores them). Removing them first makes the items rewrite (B3d) smaller. Order change vs the brief (B4 before B3d for this part only); the rest of B4 (lookup providers) stays after B3f. Branch `refactor/F019-B4a-links`, worktree `/Users/federico/Developer/collections-app/backend-F019-B4a`. Rules as B3a.md.

## T1 · Remove the code
- Delete `internal/streamlinks/` (and `docs/modules/streamlinks.md`).
- `internal/stores`: keep ONLY the provider key list (`Providers()`, `Valid`, `ValidateKeys`) used by workspace settings, the `stores` field validation and `httpapi/stores.go`; delete `Link`, `LinkInput`, the Amazon country table and their tests (keep tests of what remains).
- `internal/items/stores.go`: delete `storeLinks`, `buildStoreLinks`, `FillStoreLinks`; `Item.StoreLinks` field and its fill in `Get`/`List`; `internal/search/search.go`: delete `fillStoreLinks` and its calls; `internal/httpapi/items.go`: delete `streamlinks.AddToMetadata` calls and the `store_links` injection in `itemBody`/`itemSummaryBody`; `internal/items/write.go` `validateClientMetadata`: stop special-casing `platform_links` (`k != "link"` only); `internal/definitions/validate.go`: `store_links` is no longer a reserved field key (remove that clause and its test case).
- `db/queries/types.sql`: delete `ListStoresFieldKeys` (grep for other users first); `make generate`.
- Tests: delete tests that only test the removed feature (httpapi `stores_test.go` link cases, `TestF016_StoreLinks...`, streamlinks tests, items tests asserting `store_links`/`platform_links` in responses) and replace the response assertions in tests that merely touch the fields by assertions that the keys are ABSENT in item, row, search and recent responses (add one table-driven test `TestB4a_NoLinkFields` covering book item, movie item, list rows, search, recent). Every other test stays.
Must pass: `go build ./... && go vet ./... && make fmt-check && make lint && go test -count=1 ./...`.

## T2 · Contract and docs
`api/openapi.yaml`: remove `store_links` and `streaming.platform_links` from schemas, descriptions and examples (lines ~1735-1873, 2406-2433, 2603; grep both names); keep `streaming.link` (TMDB's own). Bump `info.version` to 0.17.0 with a changelog line if the file keeps one. `make generate` (oapi) and `make lint-api`. Do not tag. docs-keeper pass is the orchestrator's.
