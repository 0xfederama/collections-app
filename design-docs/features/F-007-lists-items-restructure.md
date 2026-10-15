# F-007 — Lists and items restructure + exploration fixes

Status: **done** (backend#18, web#28 merged 2026-10-15)    Release: 1.1.0 (backend and web; versions diverge after this, D-080)    Roadmap: ROADMAP.md §6
Repos: backend | web | parent    Approved by the user: 2026-10-15

## Why
The 1.0 model is more general than the way the app is used. Lists mix item types, and each type comes with a long set of
predefined fields. The exploration session on a fresh test env also found UI issues that shouldn't survive into the UI
refresh. Reshaping now, before the e2e tests (F-003) and the UI refresh (F-002), means both get built once, on the final model.

## Decisions (with the user, 2026-10-15)
- **One kind per list.** The kind is chosen when the list is created, and every item in the list has that kind. Items no
  longer carry their own kind: it's derived from the list. The kind label under each item goes away. A finer sub-type, such
  as comedy vs drama, may come back later.
- **Common item fields:** title, image, **website** (renamed from "official website", because it isn't always the official
  one), and the Markdown description with its history. **Summary and status are removed.**
- **Price can be added, but it's never a default.**
  - No kind shows a price until you add one with a "+" ("Add price").
  - A price is a **single price or a range**, plus a currency.
  - Removing the price hides the field again.
  - Existing prices are kept as they are.
- **Kind fields are trimmed to the essentials.** Each kind has one **sort key**:

  | Kind | Fields kept | Sort key |
  |---|---|---|
  | Item (`generic`) | none | none |
  | Movie | release year, runtime (min), IMDb URL, streaming platforms + country | release year |
  | TV show | first-air year, end year, seasons, IMDb URL, streaming platforms + country | first-air year |
  | Motorcycle | make, model, model year, displacement (cc), power (hp), licence class | displacement |
  | Car | make, model, model year, fuel type, power (hp) | power |
  | Camera | make, model, release year, sensor format, megapixels | megapixels |

- **Sort modes:** manual (the default, still with drag), title, updated, and **the kind's sort key**. That last mode is
  ascending, puts empty values last, and doesn't exist for generic lists.
- **Never lose data.** The migration does three things:
  - Summary, status and every dropped kind field are moved into the item's description, as a "From 1.0" Markdown
    block at the top. This creates a new content version.
  - Each list gets the kind of its items.
  - A list that still mixes kinds is split into one list per kind in the same folder, named "<name> · <Kind>". This is a
    safety net only: you keep films and TV shows in separate lists anyway.

## User stories
### Backend
- **F007-B1 · List kind.** As a user, I want each list to have one kind, so that its items share the same fields.
  Acceptance:
  - A list has a `kind`, which is required on create.
  - Items no longer send a kind. The API returns `kind` as read-only, derived from the list.
  - Moving an item to a list of another kind is rejected with a clear error.
  - A list's kind can be changed. If the list has items, that change clears their kind fields; the web client warns first.
  - Search results still show the kind.
- **F007-B2 · Fields.** As a user, I want only the fields I actually use, so that items stay simple.
  Acceptance:
  - Summary and status are removed from the API and the schema.
  - Price stays optional: a single price (min = max) or a range, with a currency. The API should make the single case
    easy, e.g. accept just `amount` or return `min == max`.
  - `official_url` becomes `website`, and the "Official site" link button becomes "Website" (PRODUCT §9).
  - The kind validators match the table above.
  - The workspace default currency is removed if nothing else uses it.
- **F007-B3 · Sort by kind key.** As a user, I want to sort a list by its kind's sort key, so that I can see, say,
  motorcycles by cc. Acceptance:
  - A new sort mode sorts by the key ascending, with empty values last.
  - It's rejected on generic lists.
  - The manual order is kept when the mode is switched.
- **F007-B4 · List description in Markdown.** As a user, I want a Markdown description on a list, e.g. for links that
  apply to all its items. Acceptance:
  - The existing `lists.description` becomes Markdown, with a 64 KiB cap.
  - It's edited with the list's `version` (optimistic concurrency).
  - It has no version history. That can be added later.
- **F007-B5 · Migration.** As a user, I want my existing data to survive the restructure. Acceptance:
  - The migration follows the "never lose data" rule above.
  - It's idempotent, and it's tested on a fixture that has mixed lists and every removed field filled in.
  - `make test-backup` still passes, since the schema changed.
- **Contract:** `api-v0.3.0` (breaking), tagged once the backend PR(s) are merged.

### Web
Exploration fixes. They don't depend on the backend, so they can go first:
- **F007-W1 · No "collections".** The sidebar no longer mentions collections; there is only one, and multi-collection is
  not planned. Acceptance:
  - The header is neutral (e.g. "Library").
  - The empty state reads like "No lists yet".
  - The header's + button is clearly labelled as creating a folder or a list, and does exactly that.
  - The loading and error texts follow the same wording.
- **F007-W2 · Folder rows.** Acceptance:
  - The expand arrow is removed.
  - Folders are aligned to the left edge like lists.
  - The folder icon itself shows the state (closed / open folder) and toggles it.
  - Keyboard expand and collapse still work.
- **F007-W3 · No move up/down on folders.** Acceptance:
  - "Move up / Move down" is removed from the folder menu, because drag-and-drop does it.
  - The keyboard reorder alternative is kept (a11y). Choose the least visible form.
- **F007-W4 · One description.** Acceptance:
  - Summary disappears with B2.
  - List rows don't show any description text.
  - The Markdown description is shown only in the selected item's detail.
- **F007-W5 · No breadcrumbs** at the top of the page.
- **F007-W6 · Appearance toggle** moves into the sidebar.

Restructure (needs `api-v0.3.0`):
- **F007-W7 · List kind in the UI.** Acceptance:
  - The kind is picked when a list is created, and can be changed in the list settings, with a warning when the list has
    items.
  - The item forms no longer ask for a kind.
  - The kind label under each item is removed.
  - When moving items, only lists of the same kind are offered.
- **F007-W8 · Fields.** Acceptance:
  - The item form and the detail view show only the common fields and the trimmed kind fields.
  - Status and summary are gone.
  - Price is hidden until it's added with "+ Add price". It's entered as a single price (the default) or switched to a
    range, and it can be removed again. The detail view shows "€ 1,200" for a single price and "€ 1,000–1,400" for a range.
  - "Website" replaces "Official site".
- **F007-W9 · Sort by kind key.** The sort menu offers the kind's key (e.g. "Displacement") on non-generic lists. Manual
  stays the default.
- **F007-W10 · List description.** Acceptance:
  - The list page shows the Markdown description, collapsible, with links opening safely as on items.
  - It's edited with the same Edit/Preview editor.
- **Release:** both repos are bumped to **1.1.0**.

### Parent (top-level orchestrator)
- Bump the pointers.
- Update PRODUCT §3–§4 and §9, and DATA_MODEL, to match the new model.
- Tag `v1.1.0`.

## Contract impact
This is breaking: **`api-v0.3.0`**. The web stories W1–W6 don't need the new contract and can be built first. W7–W10 pin
to `api-v0.3.0` once it's tagged.

## Constraints
- Keep the per-kind validator registry and `metadata` JSONB (ARCHITECTURE §7). TMDB must still fit: a movie list gets the
  lookup.
- Lean (D-034). Anything editable uses a `version`.
- **One-off workflow for this feature (D-079):**
  - The orchestrators run Sonnet 5.5.
  - Workers only write code; they run no tests.
  - The orchestrator runs the full gate once, at the end.
  - The work goes in **one PR per repo**. Backend may split it in two only if the concepts differ a lot.

## Out of scope (in the pool or in F-002)
- List icons.
- Dragging from anywhere on a row.
- Automatic image lookup.
- Editing items inline without an edit mode.
- User-defined kinds.
- List import.
- Visual design.

## Open questions
| ID | Question | Default |
|---|---|---|
| F007-Q3 | Kind change on a non-empty list | Allowed, with a warning; kind fields are cleared |
| F007-Q4 | List description history | None for now |

## Repo breakdown (filled by the repo orchestrators)
### Backend
| Task | Story | Branch | Worker result | Flags reviewed | PR |
| T1 schema + queries + spec: migration 000002 (kind on lists, drops, data move/split), sqlc queries, `openapi.yaml` 0.3.0, regenerate | B1 B2 B3 B4 B5 | `feature/F007-lists-items-restructure` | done | flags reviewed, accepted | [backend#18](https://github.com/0xfederama/collections-app-backend/pull/18) |
| T2 services + handlers: list kind, kind change, move check, trimmed kinds, price `amount`, `website`, settings currency removal, search kind | B1 B2 | same | done | flags reviewed, accepted | [backend#18](https://github.com/0xfederama/collections-app-backend/pull/18) |
| T3 sort by kind key + list Markdown description | B3 B4 | same | done | flags reviewed, accepted | [backend#18](https://github.com/0xfederama/collections-app-backend/pull/18) |
| T4 migration fixture test + docs (docs-keeper) | B5 | same | done | flags reviewed, accepted | [backend#18](https://github.com/0xfederama/collections-app-backend/pull/18) |
### Web
| Task | Story | Branch | Worker result | Flags reviewed | PR |
| T1 sidebar: no "collections", folder rows (icon toggles), no folder move up/down, theme toggle in sidebar | W1 W2 W3 W6 | `feature/lists-items-restructure` | done | flags reviewed, accepted | [web#28](https://github.com/0xfederama/collections-app-frontend-web/pull/28) |
| T2 list view: no description text on rows, no breadcrumbs | W4 W5 | same | done | flags reviewed, accepted | [web#28](https://github.com/0xfederama/collections-app-frontend-web/pull/28) |
| T3 pin `api-v0.3.0` (api:sync), list kind in create/settings, move picker by kind | W7 | same | done | flags reviewed, accepted | [web#28](https://github.com/0xfederama/collections-app-frontend-web/pull/28) |
| T4 item fields: trimmed kinds, price add/range/remove, website, no status/summary/kind label | W8 | same | done | flags reviewed, accepted | [web#28](https://github.com/0xfederama/collections-app-frontend-web/pull/28) |
| T5 sort by kind key + list Markdown description | W9 W10 | same | done | flags reviewed, accepted | [web#28](https://github.com/0xfederama/collections-app-frontend-web/pull/28) |
| T6 version 1.1.0, docs-keeper, gate, PR | release | same | done | flags reviewed, accepted | [web#28](https://github.com/0xfederama/collections-app-frontend-web/pull/28) |

## Log
- 2026-10-15: draft created from the user's re-plan.
- 2026-10-15: exploration findings and the user's decisions added; approved.
- 2026-10-15: backend B1–B5 shipped in one PR (backend#18, squash `be8a532`); gate and `make test-backup` green; tags `api-v0.3.0`, `v1.1.0`. Deviations: JSON body limit 2 MiB on list create/update (64 KiB description); a PATCH of kind plus other fields bumps the list version twice; each trashed piece of a split list gets its own trash batch.
- 2026-10-15: web W1–W10 delivered in one PR, squash merged (web#28, version 1.1.0, contract api-v0.3.0). Gate green after fixing 4 stale test assertions. Follow-ups: AT-21 reorder web test lost with the menu items; price shows `€1,200` (not `€ 1,200`); list kind is changed via the Rename dialog.
- 2026-10-15: parent: pointers bumped, PRODUCT §3/§4/§6/§9 and DATA_MODEL updated. Done.
