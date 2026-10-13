# Product Spec

## 1. Vision

A calm, image-forward place for two people to collect and compare things they like or want:
movies to watch, motorcycles to consider, things to buy. It should feel like a polished collection
product, not an admin dashboard and not a project-management tool.

## 2. Users

- MVP: two trusted people sharing **one workspace**, with no accounts and no identity. Edits are anonymous.
- Access only from localhost or a trusted private network (LAN, VPN, or a private tunnel such as Tailscale).

## 3. Concepts

| Concept | Rules |
|---|---|
| Workspace | Exactly one in MVP, auto-created on first start. Has a name and settings |
| Folder | Nestable without a depth limit. Lives at the root or inside a folder. Manually ordered among siblings |
| List | Lives at the workspace root or inside a folder. Has a name, an optional description, a display mode, and a sort mode. Manually ordered among sibling lists |
| Item | Belongs to exactly one list. Manually ordered within the list |

- Folders and lists are separate sibling groups inside a parent. In the sidebar, folders show first and then lists, each in its own manual order.
- IDs are UUIDs and stay stable across move, rename, trash, and restore.

## 4. Items

### Common fields

| Field | Required | Rules |
|---|---|---|
| Title | yes | 1–300 chars, trimmed |
| Kind | yes | `generic` (default), `movie`, `tv_show`, `motorcycle`, `car`, `camera` (see §4.2) |
| Summary | no | ≤ 1000 chars, plain text |
| Status | no | Free text ≤ 100 chars (e.g. "want", "watched", "test-ridden"). No workflows |
| Image | no | One primary image: **either** an external URL **or** an uploaded file, never both |
| Price | no | `min`/`max` decimals ≥ 0 with 2 decimal places. A single price means min = max, and either bound may be omitted. Currency (ISO 4217) is required if any bound is set |
| Official website | no | `http`/`https` URL ≤ 2048 chars |
| Description | no | Markdown ≤ 1 MiB with version history (§5) |
| Kind metadata | depends on kind | Validated per kind by the backend |

Workspace default currency is EUR and pre-fills new items.

### 4.2 Kinds

MVP kinds (D-028). Every kind-specific field is **optional**. Exact types and ranges are in DATA_MODEL §2.1.

| Kind | UI label | Kind fields |
|---|---|---|
| `generic` | Item | none |
| `movie` | Movie | release year, runtime (min), IMDb URL, streaming platforms + country |
| `tv_show` | TV show | first-air year, end year (empty = ongoing), seasons, IMDb URL, streaming platforms + country |
| `motorcycle` | Motorcycle | make, model, model year, segment, displacement (cc), power (hp), torque (Nm), wet weight (kg), seat height (mm), licence class (AM/A1/A2/A) |
| `car` | Car | make, model, model year, trim, body type, fuel type, transmission, power (hp), seats, electric range (km) |
| `camera` | Photo camera | make, model, release year, camera type, sensor format, megapixels, lens mount, weight (g) |

- Units are metric. The streaming country defaults to the workspace setting (`IT`).
- The item title stays free text (e.g. "Ducati Monster 937 SP"). Make and model are separate structured fields and are not derived from the title.
- Adding a kind later means adding a Go validator and a UI section, with no schema migration.
- Changing an item's kind replaces its metadata. The UI warns that kind-specific fields will be cleared.

## 5. Markdown description & history

- Source editor with an Edit/Preview toggle. No rich editor.
- Every save creates a new version. Saving identical content creates no version.
- Retention: the current version plus the previous N versions, where N comes from workspace settings (default 20, range 0–200). Older versions are pruned on save.
- History panel lists versions (number, timestamp, size). The user can preview any version and **restore** it. Restoring creates a new version with that content, so history stays linear.
- No diff and no merge in MVP.

## 6. Organizing

- **Create / rename / move / delete** folders, lists, and items.
- **Move:** folders into another folder or the root (never into themselves or their descendants), lists into a folder or the root, items into another list. A moved resource goes to the **end** of its destination.
- **Manual reorder** with drag-and-drop, plus a keyboard alternative.
- **List display mode** (shared): `compact`, `thumbnail`, or `grid`.
- **List sort mode** (shared): `manual` (default), `title` (A→Z), or `updated` (newest first). Switching never destroys the manual order. Drag-reorder is available only in `manual` mode.
- **In-list filter:** a client-side or server-side title filter for the current list.

## 7. Security boundary (mandatory)

- No auth in MVP, so the API must **never** be reachable from the public internet.
- By default, Compose publishes the API port on `127.0.0.1` only. LAN or VPN exposure is an explicit, documented opt-in.
- Auth (Phase 3) is required before any public exposure.

## 8. Search

- Global search over **item titles only**, case-insensitive substring match.
- Results show the item (thumbnail, title, kind) and its path: `Folder › Subfolder › List`.
- Trashed items, and items inside trashed lists or folders, never appear.

## 9. External links (item detail)

Exactly three buttons, always in this order:
1. **Google**: `https://www.google.com/search?q=<query>`. The query is the title, plus context by kind: movie → `<title> <release_year> film` (year only if set), TV show → `<title> TV series`, all other kinds → title only.
2. **Reddit**: same query plus ` site:reddit.com`, via Google.
3. **Official site**: the stored URL. If none is stored, the button is **disabled** with the label "No official site". It never falls back to a search.

Links open in a new tab with `rel="noopener noreferrer"`. URLs are built with proper encoding.

## 10. Trash

- Delete is a soft delete and moves the selection to Trash. Deleting a folder or list takes **everything inside it** to Trash together as one *batch*.
- Trash lists one entry per deleted selection: name, type, former location path, deletion date, and contained counts (e.g. "3 lists, 41 items").
- **Restore** brings back exactly that batch. Things deleted separately earlier stay in Trash as their own entries.
- If the original parent is itself in Trash, restore is blocked. The user is offered either "Restore parent first" or "Restore to…" (pick an active destination, or the root where allowed).
- **Delete permanently** (purge) removes the batch's records and image files. If a purged folder contained older separately-trashed entries, those are purged too. The confirmation dialog states this, with counts.
- "Empty trash" is out of scope for MVP. Purge works per entry.
- All destructive actions require explicit confirmation.

## 11. Concurrency (two people editing)

- Each edit is checked against the version the user loaded. If someone else changed the item in between, the save is rejected and the user sees the conflict UI (UI_SPEC §9). The draft is never lost.
- Item fields and the Markdown description are versioned **independently**, so editing the description doesn't conflict with someone changing the price.

## 12. Settings

Theme (System / Light / Dark, per device, not synced), workspace name, streaming country (ISO 3166-1 alpha-2, default `IT`), default currency (default `EUR`),
and Markdown history limit (default 20).

## 13. Roadmap (order is fixed)

1. **MVP**: everything in this document.
2. **Phase 2: TMDB plus automatic refresh** (after the MVP is feature-complete): movie lookup, metadata refresh, streaming availability by country, attribution, and rate limits. User-entered values are never silently overwritten. No IMDb scraping. Verify current TMDB terms first.
3. **Phase 3: Accounts and access control** (near future): users, memberships, authz. Required before public exposure.
4. **Phase 4: Public API**, which needs a full re-discussion first. Not committed.
5. **Very distant: AI/LLM features** (description generation, comparisons, Q&A). Only with explicit user approval before saving.

Also deferred, with no committed phase: real-time collaborative editing (the architecture keeps this path open, see ARCHITECTURE §7), offline mode, advanced search, multiple images, rich editor, diffs, custom workflows, paste-image-from-clipboard, empty-trash, and auto-purge.
