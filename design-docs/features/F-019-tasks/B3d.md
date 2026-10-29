# F019-B3d task specs: items and content (PR 7)

Branch `refactor/F019-B3d-items`, worktree `/Users/federico/Developer/collections-app/backend-F019-B3d`. Rules and migration design as B3a/B3b/B3c.md; patterns `internal/lists`, `internal/definitions`. Existing tests unchanged: `internal/httpapi/{items,content,price_types,no_type,summary,recent,search,images,books_lookup,tmdb}_test.go`, `internal/items/*_test.go`, `internal/items/types/*_test.go`, `internal/content/*_test.go`, `internal/lookup/*_test.go`.

## Decisions
1. **List filtering, sorting and paging move to Go.** `ListItems`/`CountItems` (CASE/JSON operators, correlated subselect) are the SQL gymnastics the brief bans. The repository returns all active items of ONE list (plain query: items + `lists.type` + attachment dimensions); `listquery.go` filters, sorts and pages in memory with the same semantics (title/director search, text/link/number/date/boolean/streaming filters with `link` stripped, sorts manual/title/updated/price/field types, NULLS LAST, ties by id). A personal list is small; documented in the PR. `content_version` becomes a separate plain query (`MaxContentVersions(ctx, itemIDs)`).
2. Cross-feature reads (list type/sort mode, type fields, settings, folder chain for `path`, price allowed) go through consumer-declared interfaces in `items/service.go` (`Lists`, `Types`, `Settings`), wired in the composition root; the type is read BEFORE opening the item transaction (see CLAUDE.md B3c gotcha). `lists.TypeSource`-style adapters live in `httpapi/router.go`.
3. `lookupItemMetadata` stays in old code until B4; lookup (legacy) calls the NEW pure `items.ValidateMetadata(typ, fields, in, stored)` and `items.PriceAllowed(def)` with fields it loads itself, and `items.Service` Create/Get/Update (workspace from ctx).
4. Content versions (`internal/content`) migrate in the same PR (T7).

## T0 · Characterization (tests only, passing on current code)
Add `internal/httpapi/items_list_semantics_test.go` pinning what the SQL does today and the existing tests miss: search `q` matches title and (movie only) director case-insensitively and escapes `%`/`_`; text/link filter contains; number min/max inclusive and combined; date min/max; boolean filter; streaming filter ignores `link`; sort by number/date/text/boolean/streaming/price with NULLS LAST and title tiebreak for price; `updated` is descending; stable tie-break by id; limit/offset/total with filters; invalid sort/filter combinations (400 `invalid_parameter` as today: stores field, price on a type without price, filter value without field). No non-test code changes.

## T1 · Pure logic (no DB)
`internal/items/model.go` (move `Item`, `Image`, `PathSegment`, `ListParams`, `ItemPage`, `CreateInput`, `Patch`, `Price`, constants `DefaultLimit/MaxLimit`, exported helpers other packages use: `EscapeLike`, row mappers stay for now), `metadata.go` (`ValidateMetadata(typ *string, fields []types.Field, in, stored map[string]any) (map[string]any, error)` extracted from `write.go` `ValidateMetadata/validateClientMetadata/typeFieldDefs` minus DB access; `PriceAllowed`), `listquery.go` (`func queryList(all []Item, typ *string, defs ..., p ListParams) (page []Item, total int, err error)` with the semantics of the SQL; `validFilter`, `validNumberRange` etc. moved). Table-driven tests copying every case of T0 and the existing items tests at unit level. The old `items.Service` stays and keeps working (T6 deletes it).

## T2 · Repository
`internal/items/repository.go` + `db/queries/items.sql` rewrites (plain): `Get` (item + list type + attachment dims, no content_version), `GetForUpdate`, `ListByList`, `Insert`, `Update` (all editable columns incl. price, metadata JSON, image columns untouched), `Move`, `SetSortOrder`, `NextSortOrder(list)`, `MaxContentVersions(ids)`, `ListInfo(listID)` (id, name, folder_id, sort_mode, type, icon fields), `FolderChain`-style data for `path` (reuse `ListActiveFolders` rows; walk in Go), `LockTree`. Integration tests on testdb. Not wired.

## T3 · Service
`internal/items/service.go`: `Create` (defaults incl. preferred store seeding from settings, price rules, metadata validation via T1, position last, tree lock), `Get` (with path), `List` (loads list info, type fields, runs `queryList`, adds `content_version`), `Update` (merge patch rules from `write.go mergePatch`, price rules, no-op detection), `Move` (type mismatch 409, tree lock), `Reorder` (stale set 409). Same errors and error order as `internal/items/{items,write}.go` (read them line by line). Fake-store tests for the rules; the old service stays.

## T4 · Handler on Huma
`internal/items/handler.go` + `wire.go`: listItems (query params as in the spec: `sort`, `q`, `limit`, `offset`, filter params; invalid ones -> 400 `invalid_parameter` through the problem mapping), createItem (201 + Location + ETag `"i-N"`), getItem (with `path`), updateItem (If-Match, nullable PATCH fields via `httpserver.Optional`, price `{amount,currency}`), moveItem, reorderListItems. The item `metadata` object is free-form per type: keep as `map[string]any` with `additionalProperties` allowed in the schema. Register; delete the corresponding old handlers and `ifMatchPrefix` entries (not `LookupItemMetadata`, not image ops, not `DeleteItem`).

## T5 · Content
`internal/content`: `model.go`, `repository.go`, `service.go` (get current, save with 1 MiB UTF-8 byte limit => 413, history pruning to `markdown_history_limit`, restore, list/get versions; same locking: item row `FOR NO KEY UPDATE`, save bumps `items.updated_at` not version), `handler.go` (getItemContent, updateItemContent (If-Match "c-N", `MaxBodyBytes` 2 MiB), restoreContentVersion, listContentVersions, getContentVersion). Delete old `content.go`, `httpapi/content.go`; existing content tests unchanged.

## T6 · Retire the old items service
Delete `internal/items/{items,write,price,stores}.go` remnants; port `price_test.go` etc. to the new files; adapt lookup (`store.go`, `service.go`), images, search, trash, `cmd/api`, `httpapi/router.go`, test Deps literals to the new API (`items.ValidateMetadata`, `PriceAllowed`, `Service` with ctx scope); drop `FromSearchRow/FromRecentRow` use by moving the row mapping next to the search queries (search keeps its own mapper over `ListRecentItemsRow`; B3f migrates search properly). Remove `items`, `content` from the archtest legacy allowlist and the depguard exclusions; delete unused queries (`make generate`).

## After T6 (orchestrator)
`make check`, smoke on this worktree's compose, docs-keeper, CLAUDE.md note, PR, squash merge.
