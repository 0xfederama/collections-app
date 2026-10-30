# F-019 contract report: `api-v0.17.0` (hand-written, OpenAPI 3.0.3) to `api-v1.0.0` (generated, OpenAPI 3.1.0)

Machine diff: `oasdiff changelog` (1848 findings, mostly 3.0 to 3.1 typing noise; `oasdiff summary`: 52 endpoints modified, 0 added/removed). Generated file: `backend/api/openapi.yaml` (`make spec`, drift-checked by `make check-spec`).

## Unchanged
- All 52 operations: same method, path and `operationId`. All request/response field names and runtime behaviour except the list below.

## Changed (web impact)
1. **OpenAPI 3.1.** `nullable: true` is now `type: [x, "null"]`; `openapi-typescript` 7.13 generates the file without errors.
2. **Enum and union schemas are gone from `components`** (the handlers validate in the services, with their own error messages, so tags would change error answers): `DisplayMode, SortMode, ListIcon, ListIconColor, StoreKey, ItemType, TmdbType, MetadataLanguage, PinnedFields, Image, ItemBase, MovieItem/TvShowItem/VehicleItem/WishlistItem, *Metadata, Streaming, BinaryFile, SetImageUrlRequest, UploadImageRequest, RestoreConflictProblem, ValidationProblem, VersionConflictProblem`. Those fields are plain `string` / `object` now; the web defines its own unions (type keys: book, vehicle, movie, tv_show, wishlist + custom). `Item.metadata` is a free-form object; `Item.image` is `UploadImage | UrlImage | null`. Not documented per field: see `backend/docs/api-notes.md`.
3. **Added schemas:** `BlockingParent, FieldError, ListWithPath, RestoreDestination, TrashCounts`. `Problem` has one shape with `errors[]`, `current_version`, `blocking_parent`; its description lists every error `code` (single table in `internal/platform/problem/codes.go`, test-enforced).
4. **No examples** in the contract (the web's MSW `examples.ts` source is gone; use fixtures in the web repo).
5. **Removed earlier (api 0.17.0):** `store_links`, `streaming.platform_links`.
6. **Error behaviour on the migrated routes** (all in one table of `Problem` codes): unknown body key 400 `unknown_field`; wrong JSON type 400 `malformed_request`; wrong/missing Content-Type 400; value constraints 422 (`validation_failed`, `errors[]`); a repeated `If-Match` takes the first value; body validation can answer before the 428 on lists/folders/types/settings writes (items, content, images, trash use 428-first); `PUT content` with `{}` is 422 (body required); malformed multipart is 422 (was 500); number filter values Go accepted but Postgres rejected are 400 (were 500); body of exactly the size limit is 413 (Huma); a duplicate type key is 409 `type_key_taken` (was 500); deleting a type in use is 422 (spec said 409); lookups of a missing type/field after a real DB error are 500 (were 404).
7. Every GET with path/query inputs also lists 422 in the spec (Huma adds it); the server answers 400 `invalid_parameter` there.

## Behaviour that is NOT in the spec but changed
Item lists are filtered/sorted/paged in Go (same semantics, pinned by tests); text order is bytewise on lower-cased strings (equals the DB collation in the postgres alpine image); the sweeper and auto-purge need a workspace in their context.

## Not changed on purpose
`ETag`/`If-Match` prefixes (f, l, i, c, s, k, kf), pagination shape (`data/limit/offset/total`), problem+json types (`https://collection-app.invalid/problems/<code>`), all limits.
