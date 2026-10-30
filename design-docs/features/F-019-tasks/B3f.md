# F019-B3f task specs: trash and search (PR 9)

Branch `refactor/F019-B3f-trash-search`, worktree `/Users/federico/Developer/collections-app/backend-F019-B3f`. Rules/patterns as B3a..e.md. Safety net unchanged: `internal/httpapi/{trash,purge_orphans,search,recent,images}_test.go`, `api_test.go`. `[CRUCIAL]` area (trash, tree lock, files after commit).

## Decisions
- No recursive CTE survives: the two remaining ones (`ActiveFolderSubtreeIDs`, `FolderIsInSubtreeOf`) become Go walks over `ListFolderParents`-style rows (purge already works this way since B2). The tree lock is taken first in every delete, restore and purge, as today.
- Trash touches folders, lists and items tables (mark/restore rows with a batch id). Those writes are plain `UPDATE ... WHERE id = ANY(@ids)` queries in `trash/repository.go`, marked `// SEAM: moves to <feature>`. `trash` exposes no types to other features except `DefaultLimit/MaxLimit` (pagination constants): move them to `internal/platform/httpserver` as shared `Page` constants in B5; for now keep.
- Search: `GET /search` (title search with `q` escaped, paths from all active folders+lists loaded once) and `GET /recent-items`; plain queries; the row mapper stays in `search/`.

## T1 · trash model + repository
`internal/trash/model.go` (Batch, Entry, PathSegment, Destination, Restored, Page; exported names as today), `repository.go` (Postgres, InTx, Repo; workspace from ctx): batch CRUD (Insert, LockBatch, Delete, DeleteOrphans, ListIDs, ListExpiredIDs, retention days), row marking (`TrashFolders(ids, batch, now)`, `TrashLists`, `TrashItems`), restore writes (`RestoreRoot*`, `RestoreBatch*`), reads (`ListBatches` with the same output fields, `CountBatches`, `GetTrashedFolder/List/Item`, `GetAnyFolderState/ListState`), the purge reads/deletes added in B2, `FolderParents`. Rewrite `ListTrashBatches` and the two CTE queries plainly (explain in FLAGS what changed). Integration tests per method (testdb). Old Service untouched and wired.

## T2 · trash service
`internal/trash/manager.go` type `Trash` (renamed Service in T3): DeleteFolder/DeleteList/DeleteItem (version check; batch row; mark in the documented order: folders, lists in them, items of the batch's lists; older nested batches keep theirs), List, Restore (destination rules and errors `parent_in_trash` with blocking parent, `destination_unavailable`, cycle check by Go walk, sort_order appended last, version+1, batch row deleted last), Purge, PurgeAll, PurgeExpired, RunAutoPurge, file deletion AFTER commit through `storage.FileStore`, failures only logged. Tree lock first in every one of them. Fake-store tests per rule; sweeper-compatible behaviour. Old Service untouched.

## T3 · trash handler, retire the old service
Huma ops deleteFolder/deleteList/deleteItem (204, If-Match), listTrash, restoreTrashBatch, purgeTrashBatch, purgeAllTrash (read the spec paths and `httpapi/trash.go`); delete `internal/trash/trash.go`, `httpapi/trash.go`, their `ifMatchPrefix` entries, rename `Trash`->`Service`, remove `trash` from the archtest allowlist, adapt `cmd/api`/router/tests (auto purge goroutine unchanged), `make generate`, delete unused queries (rg each).

## T4 · search
`internal/search`: `repository.go`, `service.go`, `handler.go`/`wire.go` (searchItems with paging, recentItems), plain queries, paths from folders+lists loaded once per request, `q` trimmed in the service (blank => 400 `invalid_parameter`), escaping `items.EscapeLike`; delete `search.go` old and `httpapi/search.go`, remove `search` from the allowlist; existing search/recent tests unchanged.
