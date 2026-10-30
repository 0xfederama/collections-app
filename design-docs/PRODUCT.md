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
| List | Lives at the workspace root or inside a folder. Has a name, a **kind** (one per list, F-007), an optional Markdown description (≤ 64 KiB, no history), a display mode, and a sort mode. An optional emoji or built-in icon (with a named colour for the mark) identifies the list; no icon uses its kind default (F-012). Manually ordered among sibling lists |
| Item | Belongs to exactly one list and has that list's kind. Manually ordered within the list |

- Folders and lists are separate sibling groups inside a parent. In the sidebar, folders show first and then lists, each in its own manual order.
- IDs are UUIDs and stay stable across move, rename, trash, and restore.

## 4. Items

### Common fields

| Field | Required | Rules |
|---|---|---|
| Title | yes | 1–300 chars, trimmed |
| Kind | — | Not set on the item: it's the list's kind (§4.2) |
| Image | no | One primary image: **either** an external URL **or** an uploaded file, never both |
| Price | no | `min`/`max` decimals ≥ 0 with 2 decimal places. A single price means min = max, and either bound may be omitted. Currency (ISO 4217) is required if any bound is set |
| Website | no | `http`/`https` URL ≤ 2048 chars |
| Description | no | Markdown ≤ 1 MiB with version history (§5) |
| Kind metadata | depends on kind | Validated per kind by the backend |

Price is never shown by default: the user adds it ("+ Add price") as a single price or a range, and can remove it. Summary and status were removed in 1.1.0 (their 1.0 values were moved into the description).

### 4.2 Kinds

MVP kinds (D-028). Every kind-specific field is **optional**. Exact types and ranges are in DATA_MODEL §2.1.

> Since F-015 "kind" is called **type** (API and UI) and the built-in generic kind is gone: a list may have no type. Since F-014 the kinds below are the **built-in, locked** definitions (data seeded in the database, not code). You can add custom fields to them and create your own kinds in Settings → Kinds & fields; every field can be pinned, sorted and filtered. See [F-014](features/F-014-custom-fields-and-kinds.md).

| Type (key) | Name | Type fields | Default sort |
|---|---|---|---|
| `book` | Books | author, pages, ISBN, where to get it (looked up automatically) | title |
| `vehicle` | Vehicles | make, model, year, engine size (cc), power (hp) | title |
| `movie` | Movies | release year, runtime (min), IMDb URL, streaming platforms + country, director (looked up automatically) | release year |
| `tv_show` | TV shows | first-air year, end year, seasons, IMDb URL, streaming platforms + country (looked up automatically) | first-air year |
| `wishlist` | Wishlist | price (single or range, added with "+") | title |

A list with **no type** has only the common fields. Camera, motorcycle, car and the generic type no longer exist (F-018, D-105). Only the title is ever required.

- Units are metric. The streaming country defaults to the workspace setting (`IT`).
- The item title stays free text (e.g. "Ducati Monster 937 SP"). Make and model are separate structured fields and are not derived from the title.
- Adding a kind later means adding a Go validator and a UI section, with no schema migration.
- The kind belongs to the list (F-007). Changing a list's kind clears its items' kind fields; the UI warns first. Items move only between lists of the same kind.

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
- **List sort mode** (shared): `manual` (default), `title` (A→Z), `updated` (newest first), or `kind_key` (the kind's sort key, ascending, empty last; not on generic lists). Switching never destroys the manual order. Drag-reorder is available only in `manual` mode.
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
3. **Website**: the stored URL. If none is stored, the button is **disabled**. It never falls back to a search.

Links open in a new tab with `rel="noopener noreferrer"`. URLs are built with proper encoding.

## 10. Trash

- Delete is a soft delete and moves the selection to Trash. Deleting a folder or list takes **everything inside it** to Trash together as one *batch*.
- Trash lists one entry per deleted selection: name, type, former location path, deletion date, and contained counts (e.g. "3 lists, 41 items").
- **Restore** brings back exactly that batch. Things deleted separately earlier stay in Trash as their own entries.
- If the original parent is itself in Trash, restore is blocked. The user is offered either "Restore parent first" or "Restore to…" (pick an active destination, or the root where allowed).
- **Delete permanently** (purge) removes the batch's records and image files. If a purged folder contained older separately-trashed entries, those are purged too. The confirmation dialog states this, with counts.
- F-012 adds **Empty trash** with a permanent-delete confirmation and contained counts.
- Optional automatic deletion runs daily and at startup: off by default, with 7/30/90-day choices in Settings.
- All destructive actions require explicit confirmation.

## 11. Concurrency (two people editing)

- Each edit is checked against the version the user loaded. If someone else changed the item in between, the save is rejected and the user sees the conflict UI (UI_SPEC §9). The draft is never lost.
- Item fields and the Markdown description are versioned **independently**, so editing the description doesn't conflict with someone changing the price.

## 12. Settings

Theme (System / Light / Dark, per device, not synced), workspace name, streaming country (ISO 3166-1 alpha-2, default `IT`), default currency (default `EUR`),
Markdown history limit (default 20), and Delete trash automatically (Off / 7 / 30 / 90 days, saved immediately; F-012).

> **Log viewer (F-019-B6):** when `LOGS_UI=true` the backend serves its recent logs at `/admin/logs/view` (JSON at `/admin/logs`), from an in-memory buffer; off by default in production, no auth yet (loopback/tailnet only until the security review).

## 13. Roadmap (order is fixed)

1. **MVP**: everything in this document.
2. **Phase 2: TMDB plus automatic refresh** (after the MVP is feature-complete): movie lookup, metadata refresh, streaming availability by country, attribution, and rate limits. User-entered values are never silently overwritten. No IMDb scraping. Verify current TMDB terms first.
3. **Phase 3: Accounts and access control** (near future): users, memberships, authz. Required before public exposure.
4. **Phase 4: Public API**, which needs a full re-discussion first. Not committed.
5. **Very distant: AI/LLM features** (description generation, comparisons, Q&A). Only with explicit user approval before saving.

Also deferred, with no committed phase: real-time collaborative editing (the architecture keeps this path open, see ARCHITECTURE §7), offline mode, advanced search, multiple images, rich editor, diffs, custom workflows. F-012 adds clipboard images on open items, empty trash and auto-purge.
