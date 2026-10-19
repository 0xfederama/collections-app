# API Design

The private REST API is used by `collections-app-frontend-web`. Base path is `/api/v1`, and bodies are JSON (`application/json`) unless noted.
This document is the input to `backend/api/openapi.yaml` (repo `collections-app-backend`). Once the spec exists, **the spec wins**, and
divergences are fixed in the same PR.

> `/api/v1` is **not** a public API product (PRODUCT §13, Phase 4). There is no auth in MVP, so it is private-network only.

> F-012 / `api-v0.8.0`: lists and list path segments include nullable `icon` (one emoji or `i:<name>`) and `icon_color` (red/orange/amber/green/teal/blue/indigo/purple/pink/gray, built-in icons only). List create/PATCH accept them. Settings GET/PATCH adds `trash_retention_days` (`null` off, otherwise 1–365). `DELETE /api/v1/trash` permanently empties every batch and its images, idempotent 204, no If-Match. The vendored contract is authoritative for exact schemas.


> F-013 / planned `api-v0.9.0` (in progress): `GET /api/v1/tmdb/suggestions?kind=movie|tv_show&q=...` returns availability and ranked localized matches. `POST /api/v1/items/{id}/lookup` takes an item If-Match and `mode: fill|rematch|refresh`, optionally a selected `tmdb_id`; item create accepts `lookup` and `tmdb_id`. Movie/TV metadata includes `tmdb_id` and `lookup_disabled`; movie adds a pinnable/filterable `director`, with movie-only `sort=director`. Settings adds `metadata_language` (default `en-US`) and read-only `lookup_available`; missing `TMDB_API_KEY` disables lookup. Imported values/posters follow D-089: automatic refresh before six calendar months, then expiry cleanup preserving user edits if refresh fails. Exact request and response schemas live in the backend spec.

> F-016 / `api-v0.12.0`: built-in `book` type (fields `author`, `pages`, `first_publish_year`, `isbn`, `stores`, plus hidden `openlibrary_id`, `lookup_disabled`); `pinned_fields` and type default pins allow up to 3. Field type `stores` holds provider keys (`openlibrary`, `bookshop`, `amazon`, `apple_books`, `google_play_books`, `kobo`); item responses add read-only `metadata.store_links`; `GET /api/v1/store-providers`; settings add `preferred_stores` and read-only `book_lookup_available`. `GET /api/v1/books/suggestions?q=` and `source_id` on item create and `POST /items/{id}/lookup` give Open Library lookup (no API key; no retention, D-095). The canonical backend spec defines the exact schemas.
> F-014 / `api-v0.10.1`: kind definitions are workspace-scoped data. `GET`/`POST /api/v1/kinds` and kind/field management endpoints replace the fixed kind enum. A custom kind's `PATCH /api/v1/kinds/{key}` accepts partial updates to its name, `default_icon`, `allows_price`, `default_sort_field`, and `default_pinned_fields`; omitted properties are retained and explicit `null` clears nullable defaults. Defaults are checked against the kind's currently defined fields, which lets a client create a kind, add fields, then set its defaults. Built-in definitions remain locked. The canonical backend spec defines the exact schemas.

## 1. Conventions

- JSON field names are `snake_case`. IDs are UUID strings. Timestamps are RFC 3339 UTC strings.
- Money is a **decimal string** with 2 decimals (`"1299.00"`) to avoid float errors. The pattern is `^\d{1,10}\.\d{2}$`.
- Unknown request fields return `400 unknown_field` (`DisallowUnknownFields` or generator equivalent).
- `PATCH` = partial update (only supplied fields). To clear a nullable field, send `null` explicitly. `PUT` = full replacement of a sub-resource (content, image, order).
- Successful create returns `201` with the resource and a `Location` header. A delete or purge returns `204`.
- Every response to `GET /…/{id}` or to a mutation returning a single resource includes an `ETag` header.

## 2. Resource representations

```jsonc
// Folder
{ "id", "parent_folder_id": "uuid|null", "name", "sort_order", "version", "created_at", "updated_at" }

// List
{ "id", "folder_id": "uuid|null", "name", "description": "string|null",
  "display_mode": "compact|thumbnail|grid", "sort_mode": "manual|title|updated|kind_key|price", "pinned_fields": "[key,key]|null",  // ordered, at most 3 (F-016); the first is the primary field
  "sort_order", "item_count", "version", "created_at", "updated_at" }

// Item
{ "id", "list_id", "title", "kind", "summary", "status",
  "image": null
         | { "source": "url", "url": "https://…" }
         | { "source": "upload", "attachment_id", "url": "/api/v1/attachments/{id}/file",
             "thumbnail_url": "/api/v1/attachments/{id}/thumbnail", "width", "height", "original_filename" },
  "price": null | { "min": "12.00|null", "max": "15.00|null", "currency": "EUR" },  // only on motorcycle, car, camera items (0.7.0)
  "official_website_url": "string|null",
  "metadata": { …per kind… },
  "content_version": 3,          // current Markdown version (0 = empty), for display only
  "sort_order", "version", "created_at", "updated_at" }

// ItemSummary (list rows, search): Item minus metadata, with image reduced to { thumbnail_url | url }

// Content
{ "item_id", "version", "body", "updated_at" }

// Settings
{ "workspace_name", "streaming_country_code", "default_currency", "markdown_history_limit", "version" }

// TrashEntry
{ "id": "batch uuid", "root_type": "folder|list|item", "root_id", "root_name",
  "former_path": [{ "type": "folder|list", "id", "name" }], "deleted_at",
  "counts": { "folders": 0, "lists": 2, "items": 17 },
  "restorable_in_place": true }    // false when the original parent is trashed or gone
```

## 3. Optimistic concurrency (ETags)

| Resource | ETag | Bumped by |
|---|---|---|
| Folder | `"f-{version}"` | rename, move, restore |
| List | `"l-{version}"` | rename, description, display_mode, sort_mode, move, restore |
| Item | `"i-{version}"` | any PATCH field, image change, move, restore |
| Content | `"c-{version}"` | content save or restore (independent stream) |
| Settings | `"s-{version}"` | any settings or workspace-name change |

- The ETag is derived from `version`, which is also in the body. Clients holding a resource from a collection response build `If-Match` from it (`lib/api` does this).
- **Requires `If-Match`:** `PATCH` and `DELETE` on folders/lists/items, all `…/move`, `PUT …/content`, `POST …/content/restore`, `PUT` and `DELETE …/image`, `PATCH /settings`.
  - Missing returns `428 precondition_required`. Mismatched returns `412 version_conflict`, with the problem including `current_version`.
  - `If-Match: *` is **rejected** (treated as missing). Clients must state what they edited.
- **No `If-Match`:** creates, `PUT …/order` (protected by set-equality, `409 order_stale`), trash restore and purge.
- The server never retries a stale write on the client's behalf, and the client never auto-resubmits with a fresh ETag.

## 4. Errors: RFC 9457 `application/problem+json`

```json
{ "type": "https://collection-app.invalid/problems/version-conflict",
  "title": "Resource was modified", "status": 412,
  "detail": "Item was changed by someone else.", "code": "version_conflict",
  "current_version": 8 }
```

| Status | `code` | When |
|---|---|---|
| 400 | `malformed_request`, `unknown_field`, `invalid_parameter` | Bad JSON, unknown field, bad query param |
| 404 | `not_found` | Missing **or trashed** resource (for non-trash endpoints) |
| 409 | `cycle_detected` | Folder moved into itself or a descendant |
| 409 | `parent_in_trash` | Restore without destination when the parent is trashed. Includes `blocking_parent {type,id,name}` |
| 409 | `destination_unavailable` | Move or restore destination missing or trashed |
| 409 | `order_stale` | Reorder set mismatch |
| 412 | `version_conflict` | Stale `If-Match`. Includes `current_version` |
| 413 | `payload_too_large` | Image > 10 MiB, Markdown > 1 MiB, JSON body over limit |
| 415 | `unsupported_media_type` | Image not JPEG/PNG/WebP by content sniffing (SVG always rejected) |
| 422 | `validation_failed` | Field rules. Includes `errors: [{ "field": "price.max", "message": "…" }]` |
| 428 | `precondition_required` | Missing `If-Match` |
| 500 | `internal` | Generic message plus `request_id`. Never SQL, paths, or stack traces |

## 5. Endpoints

### Health (outside `/api/v1`)
| | |
|---|---|
| `GET /healthz` | 200 if the process is up |
| `GET /readyz` | 200 if DB reachable and `DATA_DIR` writable, else 503 |

### Workspace & settings
| Method | Path | Notes |
|---|---|---|
| GET | `/api/v1/settings` | Settings, including workspace name |
| PATCH | `/api/v1/settings` | `If-Match`. Fields: `workspace_name`, `streaming_country_code`, `default_currency`, `markdown_history_limit`. Lowering the limit prunes on the next save per item, not immediately |

### Tree (sidebar)
| GET | `/api/v1/tree` | All **active** folders and lists, flat: `{ "folders": [Folder], "lists": [List] }`. Client builds the tree. Unpaginated (small by nature) |

### Folders
| Method | Path | Notes |
|---|---|---|
| POST | `/api/v1/folders` | `{ name, parent_folder_id? }` → 201. A missing or trashed parent → `409 destination_unavailable` |
| GET | `/api/v1/folders/{id}` | |
| PATCH | `/api/v1/folders/{id}` | `If-Match`. `{ name }` |
| DELETE | `/api/v1/folders/{id}` | `If-Match`. Moves the subtree to Trash → 204 |
| POST | `/api/v1/folders/{id}/move` | `If-Match`. `{ parent_folder_id: uuid\|null }` |
| PUT | `/api/v1/folders/order` | `{ parent_folder_id: uuid\|null, ids: [uuid] }` orders child **folders** of that parent → 204 |

### Lists
| Method | Path | Notes |
|---|---|---|
| POST | `/api/v1/lists` | `{ name, folder_id?, description?, display_mode?, sort_mode? }` → 201. A missing or trashed folder → `409 destination_unavailable` |
| GET | `/api/v1/lists/{id}` | Includes `path: [{type:"folder",id,name}]` |
| PATCH | `/api/v1/lists/{id}` | `If-Match`. `name, description, display_mode, sort_mode, pinned_fields` (`null` resets) |
| DELETE | `/api/v1/lists/{id}` | `If-Match` |
| POST | `/api/v1/lists/{id}/move` | `If-Match`. `{ folder_id: uuid\|null }` |
| PUT | `/api/v1/lists/order` | `{ folder_id: uuid\|null, ids: [uuid] }` orders child **lists** of that folder or the root → 204 |

### Items
| Method | Path | Notes |
|---|---|---|
| GET | `/api/v1/lists/{id}/items` | `?sort=manual\|title\|updated\|kind_key\|price` (default: the list's `sort_mode`), `?q=` title filter, `?limit=` (default 50, max 200), `?offset=`. Returns `{ data: [ItemSummary], page: { limit, offset, total } }`. Tie-breaker `id`. `kind_key` only on kinds with a sort key; `price` only on kinds with a price (0.7.0) |
| POST | `/api/v1/lists/{id}/items` | `{ title, kind?, summary?, status?, price?, official_website_url?, metadata? }` → 201 Item. `price` only on motorcycle, car, camera (0.7.0). Image and content are set via their own endpoints after creation |
| GET | `/api/v1/items/{id}` | Item, plus `path` (folders and list) |
| PATCH | `/api/v1/items/{id}` | `If-Match`. Any of: `title, kind, summary, status, price, official_website_url, metadata`. If `kind` changes and `metadata` is absent, metadata resets to `{}` |
| DELETE | `/api/v1/items/{id}` | `If-Match` |
| POST | `/api/v1/items/{id}/move` | `If-Match`. `{ list_id }` |
| PUT | `/api/v1/lists/{id}/items/order` | `{ ids: [uuid] }`. **All** active items of the list. Allowed regardless of `sort_mode` → 204 |

Max list page is 200 (not 100 as in the archive) so typical lists render in one request.

### Image
| Method | Path | Notes |
|---|---|---|
| PUT | `/api/v1/items/{id}/image` | `If-Match`. **Either** `multipart/form-data` with field `file` (≤ 10 MiB; JPEG/PNG/WebP by sniffing) **or** JSON `{ "url": "https://…" }`. Replaces any existing image of either source. Returns Item |
| DELETE | `/api/v1/items/{id}/image` | `If-Match`. Returns Item |
| GET | `/api/v1/attachments/{id}/file` | Original. `Cache-Control: private, max-age=31536000, immutable` (replacement always makes a new ID) |
| GET | `/api/v1/attachments/{id}/thumbnail` | JPEG thumbnail, same caching |

### Content (Markdown)
| Method | Path | Notes |
|---|---|---|
| GET | `/api/v1/items/{id}/content` | Content. Version 0 with empty body if never saved |
| PUT | `/api/v1/items/{id}/content` | `If-Match: "c-N"`. `{ body }` (≤ 1 MiB UTF-8). Identical body returns 200 with the same version |
| GET | `/api/v1/items/{id}/content/versions` | `{ data: [{ version, size_bytes, created_at }] }`, newest first, unpaginated (≤ 201) |
| GET | `/api/v1/items/{id}/content/versions/{version}` | Content of that version (for preview). 404 if pruned. Its `ETag` is that version's `"c-N"` |
| POST | `/api/v1/items/{id}/content/restore` | `If-Match: "c-N"` (current). `{ version }` → creates a new version, returns Content |

### Search
| GET | `/api/v1/search?q=&limit=&offset=` | `q` 1–200 chars, required. `{ data: [{ item: ItemSummary, path: [{type,id,name}] }], page }` |

### Recent items (Home, D-070)
| GET | `/api/v1/recent-items?limit=` | `limit` 1–50, default 12. `{ data: [{ item: ItemSummary, path }] }` like search results, no `page`. Active items, `updated_at DESC, id` (a PATCH or content save moves an item up) |

### Trash
| Method | Path | Notes |
|---|---|---|
| GET | `/api/v1/trash` | `{ data: [TrashEntry], page }`, newest first |
| POST | `/api/v1/trash/{batch_id}/restore` | Optional `{ destination: { folder_id: uuid\|null } }` for folders/lists, `{ destination: { list_id } }` for items. Returns `{ root_type, root_id }` |
| DELETE | `/api/v1/trash/{batch_id}` | Purge → 204 |

Trash is addressed by **batch id** (simpler than `{type}/{id}` from the archive, and it maps 1:1 to UI entries).

## 6. Limits & headers

- JSON body limit is 64 KiB on most routes and 2 MiB on content PUT. Multipart limit is 10 MiB plus 64 KiB overhead.
- ~~CORS (dev only)~~: dropped (D-033). Dev and prod are both same-origin (Vite proxy / Caddy), so the API sends no CORS headers.
- Every response carries `X-Request-Id`.

## 7. OpenAPI requirements

- One file, `api/openapi.yaml` (split later only if tooling supports a bundled artifact).
- Every operation has `operationId` (camelCase verbNoun, e.g. `updateItem`), tags, all response codes above that apply, examples for main schemas (used by MSW mocks in web), and `If-Match`/`ETag` header definitions.
- Shared components: `Problem`, `ValidationProblem`, `Page`, `Price`, `Image`, `PathSegment`.
- Version field `info.version` follows the `api-v0.N.0` tags.
