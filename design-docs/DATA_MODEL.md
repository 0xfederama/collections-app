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
  default_currency       CHAR(3) NOT NULL DEFAULT 'EUR' CHECK (default_currency ~ '^[A-Z]{3}$'),
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
  trash_batch_id   UUID NULL REFERENCES trash_batches(id) ON DELETE SET NULL,  -- see §4 purge
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
  description    TEXT NULL CHECK (char_length(description) <= 2000),
  display_mode   TEXT NOT NULL DEFAULT 'thumbnail' CHECK (display_mode IN ('compact','thumbnail','grid')),
  sort_mode      TEXT NOT NULL DEFAULT 'manual'    CHECK (sort_mode IN ('manual','title','updated')),
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
  kind                 TEXT NOT NULL DEFAULT 'generic' CHECK (kind ~ '^[a-z][a-z0-9_]{0,31}$'),
  summary              TEXT NULL CHECK (char_length(summary) <= 1000),
  status               TEXT NULL CHECK (char_length(status) <= 100),
  image_url            TEXT NULL CHECK (char_length(image_url) <= 2048),
  image_attachment_id  UUID NULL UNIQUE,
  price_min            NUMERIC(12,2) NULL CHECK (price_min >= 0),
  price_max            NUMERIC(12,2) NULL CHECK (price_max >= 0),
  currency             CHAR(3) NULL CHECK (currency ~ '^[A-Z]{3}$'),
  official_website_url TEXT NULL CHECK (char_length(official_website_url) <= 2048),
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
CREATE INDEX ON items (workspace_id, kind) WHERE deleted_at IS NULL;
CREATE INDEX ON items USING gin (lower(title) gin_trgm_ops) WHERE deleted_at IS NULL;
CREATE INDEX ON items (trash_batch_id) WHERE trash_batch_id IS NOT NULL;
```
`currency` is stored only when a price exists. The API pre-fills the default currency client-side, and the server
rejects a price without a currency (422) rather than guessing.

### 2.1 Kind metadata (`items.metadata`)

Metadata is validated in Go by a per-kind validator registry (`internal/items/kinds`). Unknown keys are rejected (400 `unknown_field`, or 422 for a wrong kind),
all keys are optional, and `null` is not stored (the key is omitted). Text fields are trimmed and limited to 100 chars unless noted.
Shared sub-shapes:
- `imdb_url`: string matching `^https://(www\.|m\.)?imdb\.com/title/tt\d{7,10}/?$`
- `streaming`: `{ "country": "IT" (ISO 3166-1 alpha-2, required within the object), "platforms": [string ≤ 60], ≤ 30 entries, unique case-insensitively }`

| Kind | Key | Type / rule |
|---|---|---|
| `generic` | none | must be `{}` |
| `movie` | `release_year` | int 1870–2100 |
| | `runtime_minutes` | int 1–1000 |
| | `imdb_url`, `streaming` | shared |
| `tv_show` | `first_air_year` | int 1920–2100 |
| | `end_year` | int 1920–2100, ≥ `first_air_year`; absent = ongoing |
| | `seasons` | int 1–200 |
| | `imdb_url`, `streaming` | shared |
| `motorcycle` | `make`, `model` | text |
| | `model_year` | int 1885–2100 |
| | `segment` | text ≤ 50 (e.g. naked, adventure, sport-touring) |
| | `displacement_cc` | int 1–5000 |
| | `power_hp` | number 0–1000, 1 decimal |
| | `torque_nm` | number 0–1000, 1 decimal |
| | `wet_weight_kg` | int 1–1000 |
| | `seat_height_mm` | int 300–1200 |
| | `license_class` | `AM` \| `A1` \| `A2` \| `A` |
| `car` | `make`, `model`, `trim` | text |
| | `model_year` | int 1885–2100 |
| | `body_type` | text ≤ 50 (e.g. hatchback, SUV, estate) |
| | `fuel_type` | `petrol` \| `diesel` \| `hybrid` \| `plugin_hybrid` \| `electric` \| `lpg` \| `cng` \| `hydrogen` \| `other` |
| | `transmission` | `manual` \| `automatic` |
| | `power_hp` | number 0–2000, 1 decimal |
| | `seats` | int 1–9 |
| | `electric_range_km` | int 1–2000; only allowed when `fuel_type` is `electric` or `plugin_hybrid` (or absent) |
| `camera` | `make`, `model` | text |
| | `release_year` | int 1900–2100 |
| | `camera_type` | `mirrorless` \| `dslr` \| `compact` \| `rangefinder` \| `medium_format` \| `film` \| `action` \| `other` |
| | `sensor_format` | `full_frame` \| `aps_c` \| `micro_four_thirds` \| `one_inch` \| `medium_format` \| `film_35mm` \| `other` |
| | `megapixels` | number 0.1–500, 1 decimal |
| | `lens_mount` | text ≤ 50 (e.g. Sony E, Fujifilm X) |
| | `weight_g` | int 1–10000 |

Example:
```json
{ "release_year": 1999, "runtime_minutes": 136,
  "imdb_url": "https://www.imdb.com/title/tt0133093/",
  "streaming": { "country": "IT", "platforms": ["Netflix", "Prime Video"] } }
```
The enum-like values are validated in Go, not by PG enums or CHECKs, so adding a value needs no migration. The OpenAPI spec models
metadata as a `oneOf` keyed by item `kind` (discriminator on the Item schema), so the generated TS client gets typed metadata.

### item_content_versions / item_contents (Markdown, in Postgres)
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
CREATE TABLE item_contents (
  item_id          UUID PRIMARY KEY REFERENCES items(id) ON DELETE CASCADE,
  current_version  INTEGER NOT NULL,
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  FOREIGN KEY (item_id, current_version) REFERENCES item_content_versions(item_id, version)
);
```
- An item with no `item_contents` row has empty content at **version 0**.
- **Save** (in one tx): `SELECT … FOR UPDATE` the `item_contents` row (or lock the item row when none exists). Compare with the `If-Match` version, and on mismatch return `ErrVersionConflict`. If the sha256 equals the current one, return the current version unchanged. Otherwise insert version `current+1`, upsert the pointer, then prune: `DELETE … WHERE item_id=$1 AND version <= current_new - (limit + 1)`.
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
2. Hard-delete the root row. FK `ON DELETE CASCADE` removes the descendants, content versions, and contents.
3. Delete the collected `attachments` rows. Delete `trash_batches` row B **and** any other batches whose root no longer exists, i.e. nested older batches.
4. Commit, then delete the files (log failures; the sweeper retries them).

`trash_batch_id … ON DELETE SET NULL` exists only so that deleting a batch row can never fail. The service always
clears or deletes the rows first.

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
