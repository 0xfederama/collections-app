# Data Model

The DDL below is **normative intent**. The backend agent turns it into migrations and may adjust syntax, but
any semantic change needs a DECISIONS.md entry. All timestamps are `TIMESTAMPTZ NOT NULL DEFAULT now()`
unless noted. `updated_at` is **set by the application** in every UPDATE query (no triggers), and sqlc queries must include it.

## 1. Conventions

- PKs: `UUID DEFAULT gen_random_uuid()`.
- Every domain table has `workspace_id`. Child-to-parent FKs are **composite with `workspace_id`**, so cross-workspace references are impossible.
- Kinds, statuses, and display/sort modes are `TEXT` plus `CHECK`, never PG enums. Kind-specific validation lives in Go.
- `version INTEGER NOT NULL DEFAULT 1` on every independently editable resource. Every successful mutation of that resource does `version = version + 1`. It feeds the ETag (API §3).
- `sort_order INTEGER NOT NULL`. Create and move append with `max(sort_order)+1` among active siblings. Reorder rewrites to `0..n-1`. Ties never happen within active siblings, but queries still order by `(sort_order, id)`.
- Extensions: `pgcrypto` is not needed (`gen_random_uuid()` is core in modern PG). `pg_trgm` is needed for search.

## 2. Tables

### workspaces
```sql
CREATE TABLE workspaces (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT NOT NULL CHECK (char_length(name) BETWEEN 1 AND 200),
  version     INTEGER NOT NULL DEFAULT 1,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

### workspace_settings
```sql
CREATE TABLE workspace_settings (
  workspace_id           UUID PRIMARY KEY REFERENCES workspaces(id) ON DELETE CASCADE,
  streaming_country_code CHAR(2) NOT NULL DEFAULT 'IT'  CHECK (streaming_country_code ~ '^[A-Z]{2}$'),
  markdown_history_limit INTEGER NOT NULL DEFAULT 20 CHECK (markdown_history_limit BETWEEN 0 AND 200),
  version                INTEGER NOT NULL DEFAULT 1,
  created_at, updated_at
);
```

### trash_batches
One row per user-initiated delete. Trash UI lists these rows.
```sql
CREATE TABLE trash_batches (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id  UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
  root_type     TEXT NOT NULL CHECK (root_type IN ('folder','list','item')),
  root_id       UUID NOT NULL,                -- polymorphic; integrity maintained by trash service
  root_name     TEXT NOT NULL,                -- snapshot for display
  former_path   JSONB NOT NULL,               -- [{ "type":"folder","id":"…","name":"…" }, …] snapshot at delete time
  deleted_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (id, workspace_id)
);
CREATE INDEX ON trash_batches (workspace_id, deleted_at DESC);
```

### folders
```sql
CREATE TABLE folders (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id     UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
  parent_folder_id UUID NULL,
  name             TEXT NOT NULL CHECK (char_length(name) BETWEEN 1 AND 200),
  sort_order       INTEGER NOT NULL,
  version          INTEGER NOT NULL DEFAULT 1,
  created_at, updated_at,
  deleted_at       TIMESTAMPTZ NULL,
  trash_batch_id   UUID NULL REFERENCES trash_batches(id),  -- no ON DELETE action, see §4 end (D-051)
  UNIQUE (id, workspace_id),
  FOREIGN KEY (parent_folder_id, workspace_id) REFERENCES folders(id, workspace_id) ON DELETE CASCADE,
  CHECK (parent_folder_id IS DISTINCT FROM id),
  CHECK ((deleted_at IS NULL) = (trash_batch_id IS NULL))
);
CREATE INDEX ON folders (workspace_id, parent_folder_id, sort_order) WHERE deleted_at IS NULL;
CREATE INDEX ON folders (trash_batch_id) WHERE trash_batch_id IS NOT NULL;
```
Ancestor cycles are prevented in Go. Move runs a recursive CTE in the same transaction, under
`SELECT … FOR UPDATE` on the moved folder, and rejects with `ErrCycle` if the destination is the folder or one of its descendants.

### lists
```sql
CREATE TABLE lists (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id   UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
  folder_id      UUID NULL,
  name           TEXT NOT NULL CHECK (char_length(name) BETWEEN 1 AND 200),
  kind           TEXT NOT NULL CHECK (kind ~ '^[a-z][a-z0-9_]{0,31}$'),  -- every item in the list has this kind (F-007)
  description    TEXT NULL CHECK (char_length(description) <= 65536),        -- Markdown, no history
  display_mode   TEXT NOT NULL DEFAULT 'thumbnail' CHECK (display_mode IN ('compact','thumbnail','grid')),
  sort_mode      TEXT NOT NULL DEFAULT 'manual'    CHECK (sort_mode IN ('manual','title','updated','kind_key','price')),  -- price: F-002; only on kinds with a price (0.7.0)
  pinned_fields  JSONB NULL,  -- F009-B2 (0.7.0): ordered array of at most 2 keys; NULL = kind default; reset on kind change
  sort_order     INTEGER NOT NULL,
  version        INTEGER NOT NULL DEFAULT 1,
  created_at, updated_at, deleted_at, trash_batch_id  -- as folders
  UNIQUE (id, workspace_id),
  FOREIGN KEY (folder_id, workspace_id) REFERENCES folders(id, workspace_id) ON DELETE CASCADE,
  CHECK ((deleted_at IS NULL) = (trash_batch_id IS NULL))
);
CREATE INDEX ON lists (workspace_id, folder_id, sort_order) WHERE deleted_at IS NULL;
CREATE INDEX ON lists (trash_batch_id) WHERE trash_batch_id IS NOT NULL;
```

### attachments
Independent of items, so there is no circular FK. An item points to its attachment.
```sql
CREATE TABLE attachments (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id          UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
  storage_key           TEXT NOT NULL UNIQUE,      -- e.g. images/3f/a2/<uuid>.webp  (never user-derived)
  thumbnail_storage_key TEXT NOT NULL UNIQUE,      -- images/3f/a2/<uuid>.thumb.jpg
  original_filename     TEXT NULL CHECK (char_length(original_filename) <= 255),  -- display only
  media_type            TEXT NOT NULL CHECK (media_type IN ('image/jpeg','image/png','image/webp')),
  size_bytes            BIGINT NOT NULL CHECK (size_bytes BETWEEN 1 AND 10485760),
  width                 INTEGER NOT NULL CHECK (width > 0),
  height                INTEGER NOT NULL CHECK (height > 0),
  sha256                BYTEA NOT NULL,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (id, workspace_id)
);
```

### items
```sql
CREATE TABLE items (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id         UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
  list_id              UUID NOT NULL,
  title                TEXT NOT NULL CHECK (char_length(title) BETWEEN 1 AND 300),
  image_url            TEXT NULL CHECK (char_length(image_url) <= 2048),
  image_attachment_id  UUID NULL UNIQUE,
  price_min            NUMERIC(12,2) NULL CHECK (price_min >= 0),
  price_max            NUMERIC(12,2) NULL CHECK (price_max >= 0),
  currency             CHAR(3) NULL CHECK (currency ~ '^[A-Z]{3}$'),
  website_url TEXT NULL CHECK (char_length(website_url) <= 2048),
  metadata             JSONB NOT NULL DEFAULT '{}' CHECK (jsonb_typeof(metadata) = 'object'),
  sort_order           INTEGER NOT NULL,
  version              INTEGER NOT NULL DEFAULT 1,      -- "metadata version" (everything except Markdown)
  created_at, updated_at, deleted_at, trash_batch_id,
  UNIQUE (id, workspace_id),
  FOREIGN KEY (list_id, workspace_id) REFERENCES lists(id, workspace_id) ON DELETE CASCADE,
  FOREIGN KEY (image_attachment_id, workspace_id) REFERENCES attachments(id, workspace_id),
  CHECK (NOT (image_url IS NOT NULL AND image_attachment_id IS NOT NULL)),
  CHECK (price_min IS NULL OR price_max IS NULL OR price_min <= price_max),
  CHECK ((price_min IS NULL AND price_max IS NULL) OR currency IS NOT NULL),
  CHECK ((deleted_at IS NULL) = (trash_batch_id IS NULL))
);
CREATE INDEX ON items (list_id, sort_order) WHERE deleted_at IS NULL;
CREATE INDEX ON items USING gin (lower(title) gin_trgm_ops) WHERE deleted_at IS NULL;
CREATE INDEX ON items (trash_batch_id) WHERE trash_batch_id IS NOT NULL;
```
`currency` is stored only when a price exists. The API pre-fills the default currency client-side, and the server
rejects a price without a currency (422) rather than guessing.

### 2.1 Kind metadata (`items.metadata`)

Since 1.1.0 (migration `000002_restructure`, F-007) the kind lives on the list, the item's metadata is validated against its list's kind, and each kind has a sort key (`release_year`, `first_air_year`, `displacement_cc`, `power_hp`, `megapixels`; none for generic). Prices are stored as `min`/`max`; the API also accepts a single `amount` (stored as `min` = `max`). Since 0.7.0 (migration `000007_price_kinds`, F009-B1) a price exists only on `motorcycle`, `car` and `camera` items: for `generic`, `movie` and `tv_show` the server rejects one and a price sort, and migration 000007 moved their existing prices into a "## From 1.3" content block.

Metadata is validated in Go by a per-kind validator registry (`internal/items/kinds`). Unknown keys are rejected (400 `unknown_field`, or 422 for a wrong kind),
all keys are optional, and `null` is not stored (the key is omitted). Text fields are trimmed and limited to 100 chars unless noted.
Shared sub-shapes:
- `imdb_url`: string matching `^https://(www\.|m\.)?imdb\.com/title/tt\d{7,10}/?$`
- `streaming`: `{ "country": "IT" (ISO 3166-1 alpha-2, required within the object), "platforms": [string ≤ 60], ≤ 30 entries, unique case-insensitively, "paid_platforms": optional subset of `platforms` (paid per title, F-002; stored in the platform's casing) }`

| Kind | Key | Type / rule |
|---|---|---|
| `generic` | none | must be `{}` |
| `movie` | `release_year` | int 1870–2100 |
| | `runtime_minutes` | int 1–1000 |
| | `imdb_url`, `streaming` | shared |
| `tv_show` | `first_air_year` | int 1920–2100 |
| | `end_year` | int 1920–2100, ≥ `first_air_year`; absent = ongoing |
| | `seasons` | int 1–200 |
| | `episodes_per_season` | int 1–500 (F-002) |
| | `episode_minutes` | int 1–1000, average (F-002) |
| | `imdb_url`, `streaming` | shared |
| `motorcycle` | `model_year` | int 1885–2100 |
| | `displacement_cc` | int 1–5000 |
| | `power_hp` | number 0–1000, 1 decimal |
| | `license_class` | `AM` \| `A1` \| `A2` \| `A` |
| `car` | `make`, `model` | text |
| | `model_year` | int 1885–2100 |
| | `fuel_type` | `petrol` \| `diesel` \| `hybrid` \| `plugin_hybrid` \| `electric` \| `lpg` \| `cng` \| `hydrogen` \| `other` |
| | `power_hp` | number 0–2000, 1 decimal |
| `camera` | `release_year` | int 1900–2100 |
| | `sensor_format` | `full_frame` \| `aps_c` \| `micro_four_thirds` \| `one_inch` \| `medium_format` \| `film_35mm` \| `other` |
| | `megapixels` | number 0.1–500, 1 decimal |
| | `camera_type` | `mirrorless` \| `dslr` \| `film` (F-002) |

F-002 (API 0.4.0): motorcycle and camera lost `make`/`model` (migration 000003 moves them into a "## From 1.1" content block). Pinnable keys of a list = its kind's keys plus `price` only on the kinds that have a price (motorcycle, car, camera; F009-B1, `kinds.PinnableKeys`/`kinds.HasPrice`), at most 2 in an ordered array (F009-B2, migration 000008).

Example:
```json
{ "release_year": 1999, "runtime_minutes": 136,
  "imdb_url": "https://www.imdb.com/title/tt0133093/",
  "streaming": { "country": "IT", "platforms": ["Netflix", "Prime Video"] } }
```
The enum-like values are validated in Go, not by PG enums or CHECKs, so adding a value needs no migration. The OpenAPI spec models
metadata as a `oneOf` keyed by item `kind` (discriminator on the Item schema), so the generated TS client gets typed metadata.

### item_content_versions (Markdown, in Postgres)
```sql
CREATE TABLE item_content_versions (
  item_id     UUID NOT NULL REFERENCES items(id) ON DELETE CASCADE,
  version     INTEGER NOT NULL CHECK (version >= 1),
  body        TEXT NOT NULL,
  size_bytes  INTEGER NOT NULL CHECK (size_bytes BETWEEN 0 AND 1048576),   -- octet_length(body)
  sha256      BYTEA NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (item_id, version)
);
```
- An item with no `item_content_versions` rows has empty content at **version 0**. The current version is the highest `version` for the item (`ORDER BY version DESC LIMIT 1`, served by the PK).
- **Save** (in one tx): lock the item row (`SELECT … FROM items … FOR NO KEY UPDATE`), read the latest version (number + sha256), compare with `If-Match` (mismatch → `ErrVersionConflict`). If the sha256 is equal, return the current version unchanged. Otherwise insert version `current+1`, then prune: `DELETE … WHERE item_id=$1 AND version <= current_new - (limit + 1)`.
- The latest version of an item is never deleted (prune and restore keep it), so version numbers only grow and a `c-N` ETag is never reused for a different body.
- **Restore v**: same as save, using the body of version v. It fails with 404 if v was pruned.
- Content versions are independent of `items.version`. A content save **does** bump `items.updated_at` (for "recently updated" sort) but **not** `items.version`.

## 3. Bootstrap (idempotent)

At API startup, in one transaction: `SELECT pg_advisory_xact_lock(<fixed app constant>)`. If `workspaces` is empty,
insert a workspace (name from `WORKSPACE_NAME`, default `"Our Collection"`) and its `workspace_settings` row.
If more than one workspace exists, fail startup loudly (MVP invariant). The resulting ID is cached in memory.

## 4. Trash semantics (batch cascade)

**Active** means `deleted_at IS NULL`. Every normal read filters on just this column, with no ancestor recursion.

**Delete resource R** (tx):
1. Lock R and check that it's active (otherwise 404).
2. Insert a `trash_batches` row (root type/id/name, `former_path` computed from active ancestors).
3. Set `deleted_at = now()` and `trash_batch_id = batch` on R **and on all its currently active descendants**: recursive CTE over folders, then lists in those folders, then items in those lists. Already-trashed descendants keep their own older batch.

**Restore batch B** (tx), with optional body `{ "destination": … }`:
1. Load B. The root's parent must be active. Otherwise, without a destination return `409 parent_in_trash` (include the blocking parent in the problem). With a destination, validate it the same as a move (cycle check for folders) and re-parent the root, appending it to the end.
2. Set `deleted_at = NULL` and `trash_batch_id = NULL` on all rows with `trash_batch_id = B`.
3. Re-append the root's `sort_order` to the end of its siblings, bump the root's `version`, and delete row B.

**Purge batch B** (tx, then files):
1. Collect the attachment IDs and storage keys of **all** items in the root's subtree (any batch).
2. Hard-delete the root row. FK `ON DELETE CASCADE` removes the descendants and content versions.
3. Delete the collected `attachments` rows. Delete `trash_batches` row B **and** any other batches whose root no longer exists, i.e. nested older batches.
4. Commit, then delete the files (log failures; the sweeper retries them).

`trash_batch_id` references `trash_batches` with **no `ON DELETE` action** (D-051). The service always clears or deletes
the rows first, so deleting a batch row that is still referenced is a bug and fails loudly. NO ACTION is checked after the
statement's cascades, so multi-path cascades such as `DELETE FROM workspaces` are expected to succeed (B-02 tests this).

## 5. Images

- `PUT image` (upload): validate, write the original plus thumbnail files, then in a tx insert `attachments`, set `items.image_attachment_id`, clear `image_url`, and bump `items.version`. Remember the previous attachment, and after commit delete its row and files.
- `PUT image` (url): in a tx set `image_url` and clear `image_attachment_id`, bump the version, then remove the old attachment after commit.
- `DELETE image`: clear both and bump the version, then remove the old attachment after commit.
- Thumbnail: longest side 640 px, JPEG quality ~82, EXIF orientation applied (verify a maintained EXIF library in M0-R1, or document the limitation), metadata stripped.
- Trash keeps files. Only purge (or replacement) removes them.

## 6. Search query

```sql
SELECT … FROM items i JOIN lists l ON l.id = i.list_id
WHERE i.workspace_id = $1 AND i.deleted_at IS NULL
  AND lower(i.title) LIKE '%' || lower($2) || '%' ESCAPE '\'   -- $2 has % _ \ escaped in Go
ORDER BY (lower(i.title) = lower($2)) DESC, lower(i.title), i.id
LIMIT $3 OFFSET $4;
```
Batch cascade guarantees that an item inside a trashed list or folder has `deleted_at` set, so no ancestor check is needed.
Paths are resolved by loading active folders once (they're small) and walking parents in Go.

## 7. Reorder & move

- **Reorder** (`PUT …/order`): payload is the complete ordered list of active sibling IDs. In a tx: lock the parent row, load the active sibling IDs, and require **set equality** with the payload (no missing, extra, or duplicate IDs), else return `409 order_stale`. Rewrite `sort_order = index`. Sibling `version`s are not bumped (order isn't part of a resource's editable representation).
- **Move**: `If-Match` on the moved resource, destination must be active, cycle check for folders, append to the end, and bump the moved resource's `version`.

## 8. Migrations

- golang-migrate, sequential numbering, both `up` and `down`. CI runs up → down → up on a fresh DB.
- A `down` migration never touches `DATA_DIR`. Destructive migrations must state this in a header comment, and the PR must remind the user to take a backup first (BACKUP_AND_DEPLOYMENT §4).
- Never edit a merged migration. Add a new one.

## 9. Future seams (no code now)

- Phase 3 adds `users` and `memberships(workspace_id, user_id, role)` plus the bootstrap change. All FKs are already workspace-scoped.
- Phase 2 adds `provider`, `provider_ref`, `provider_fetched_at`, and per-field override tracking, likely in metadata.
- Real-time adds `item_content_updates` and `item_content_snapshots` (see ARCHITECTURE §7).
- **To do (user, 2026-10-14):** strip metadata (EXIF incl. GPS) from uploaded **originals**, not only thumbnails (D-064 keeps originals
  byte-identical in MVP). JPEG: drop APP1/EXIF segments losslessly and bake in or keep orientation; PNG/WebP: drop metadata chunks.
  Required before any sharing or public-facing feature (Phase 3+); existing files need a one-off rewrite.
