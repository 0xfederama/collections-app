# F-018 — Type refactor: the built-in set, plural names, icons

Status: **planned** (2026-10-20, from the user's request; defaults below to confirm)    Release: backend 2.5.0, web 2.14.0    Roadmap: ROADMAP.md §6
Repos: backend | web    Contract: `api-v0.16.0` (breaking: built-in type keys change)

## Why
The built-in types grew by accident: motorcycle, car and camera are separate, a list with no type shows a price-tag icon, and type names are singular though they name a *list* ("Movie" for a list of films). This round defines the set properly, before the icon work for services (F-017).

## Decisions (with the user, 2026-10-20)
- **The built-in types are exactly five, named in the plural** (they describe a list, not one item): **Books**, **Vehicles**, **Movies**, **TV shows**, **Wishlist**. Keys stay `book`, `movie`, `tv_show`; new keys `vehicle` and `wishlist`. Books, Movies and TV shows are unchanged otherwise (fields, lookup, row layout).
- **No type is the plain list.** A list with no type shows the classic list icon (the bulleted-lines glyph, like Reminders), not a price tag.
- **Wishlist** is a new built-in type for lists of things you want to buy. Its default icon is the **price tag**. Its only type-specific field is **price** (single or range, addable with "+", as today); items otherwise have the common fields (title, image, website, description).
- **Vehicles** replaces Motorcycle and Car, with a car icon. Fields, all optional: make, model, year, engine size (cc), power (hp). Default sort: title; default pins: year and power.
- **Icons on lists (web only):**
  - With the list selected, hovering its icon in the list header shows an edit affordance; clicking (or Enter/Space, the icon is a button) opens the icon picker.
  - "Change icon" is **removed** from the "…" menu of the list header and **added** to the "…" menu of the list's row in the sidebar, next to the list name.
- **Plural everywhere:** names in the type menus, Settings → Types & fields, search results (`type_name`) and empty states. New custom types are suggested plural too (placeholder and hint), but the user's name is kept as typed.

- **Camera is removed entirely** (user, 2026-10-20): not a built-in, not converted. **Production is not in use yet**, so no data preservation is needed for it: existing camera lists simply become no-type lists and their camera fields and prices are dropped.
- **Only the title is ever required.** No field of any type is mandatory, Vehicles and Wishlist included; an item with just a title is always valid. This also holds for the types with automatic lookup (Books, Movies, TV shows): lookup fills fields when it finds a match, and an unmatched item stays valid as typed. A test per built-in type creates an item with a title only.
- **"Movie" becomes "Movies"** and so on in the displayed labels and in `type_name`. **Internal keys stay singular** (`movie`, `tv_show`, `book`, `vehicle`, `wishlist`): they are stored identifiers and enum values, where a plural would read wrong. The user doesn't care about backend compatibility (production unused, a backend refactor is coming), so the backend orchestrator may change anything else if it is clearly smarter, and records why.

## Defaults chosen (to confirm)
- **Motorcycle and Car lists become Vehicles** (production unused, so kept simple): make, model, model year, displacement and power map to the Vehicles fields; the fields Vehicles lacks (licence class, fuel type) and the prices are dropped, with no description block. The migration does not need to be reversible.
- **Built-ins stay locked, explained:** the five built-in types cannot be deleted, and their own fields cannot be removed or changed to another kind of field (F-014), because the lookups, row layouts and default pins rely on them. You can still add your own fields to them, and create or delete custom types freely. Choosing which built-ins are *shown* is not part of this round.
- **Existing labels:** `type_name` and the type labels become plural by migration; `Runtime` etc. unchanged.

## User stories
### Backend
- **F018-B1 · Built-in set.** Migration: add `vehicle` and `wishlist` definitions (fields, default pins, default icons `car` and `tag`, price allowed on Wishlist only among built-ins); pluralise the labels of the remaining built-ins; turn camera lists into no-type lists; convert motorcycle and car into `vehicle` with the field mapping above (dropped fields and prices are discarded); idempotent, tested on a fixture with every old type filled; `make test-backup`. The seed function is replaced, not renamed (as in F-014 #33). A custom type whose key collides with the new keys is handled without data loss and flagged.
- **F018-B2 · Contract and checks.** `api-v0.16.0`: the removed built-in keys disappear from the type enum and the definitions; lookups (TMDB, books), search, pins, sorts and filters keep working by key. `make audit` before the `v2.5.0` tag (D-084).

### Web
- **F018-W1 · List icon editing.** Hover/click edit on the header icon of the selected list, "Change icon" moved from the header "…" to the sidebar row "…" (and the rail where applicable), keyboard reachable with an accessible name, visible focus, works on touch (the icon is tappable; hover only adds the affordance). Needs no new contract.
- **F018-W2 · No-type icon.** A list with no type shows the classic list glyph in the tree, rail, header, search results and the type menus ("No type"). The price tag moves to Wishlist.
- **F018-W3 · New built-ins and plural names.** Types menus, Settings → Types & fields, search results and empty states use the five built-ins in the plural; Vehicles (car icon) and Wishlist (price tag) appear with their fields; the type icons map covers `vehicle` and `wishlist` and no longer references the removed keys; new-custom-type dialog hints plural.
- **Release:** web 2.14.0; update the affected e2e specs and add one for Wishlist (price only) and one for the icon edit from the header and the sidebar; `npm run audit` before the `v2.14.0` tag. Both themes keep zero serious or critical axe findings.

## Contract impact
`api-v0.16.0` (breaking for the removed built-in keys; released as a minor, like the F-016 book cleanup (user decision, STATUS)). W1 and W2 need nothing; W3 pins to it.

## Constraints
- Lean workflow D-079/D-081, AI-agnostic tiers (D-087): complex worker tier for B1 (data migration) and W3, simple for the rest. One PR per repo, gate once at the end, squash merge yourself.
- Frosted Gallery and D-083; the user-facing word is "type" (D-094).

## Out of scope
The icons for services and stores (F-017), hiding built-in types, per-type default fields beyond those listed, reading status for books.

## Open questions
| ID | Question | Default |
|---|---|---|
| F018-Q1 | Does Vehicles allow a price | No; old prices are dropped |
| F018-Q2 | Camera | Removed entirely; its lists become no-type |
| F018-Q3 | Extra Vehicles fields (fuel type, licence class) | Dropped |

## Repo breakdown (filled by the repo orchestrators)
### Backend (one PR, branch `feature/F018-type-refactor`, worktree `backend-F018`; workers write code only, the orchestrator runs the gate once, API 0.16.0, backend 2.5.0)
| Task | Story | Tier | Scope |
|---|---|---|---|
| T1 | F018-B1 | **complex** | Migration 000025: plural labels, `vehicle` and `wishlist` definitions (default icons `i:car`, `i:tag`), camera lists to no-type, motorcycle/car to `vehicle`, replaced seed + default-pin functions, collision rename of custom `vehicle`/`wishlist` keys (as 000021), migration test on a fixture with every old type filled |
| T2 | F018-B2 | simple | Remove motorcycle/car/camera from `internal/items/types`, tests and `scripts/smoke.sh`; spec 0.16.0 (type enums, per-type schemas, examples); title-only item test per built-in; `make generate` |
Decisions (D-entry in DECISIONS.md): Vehicles keep the field keys `model_year`, `displacement_cc`, `power_hp` (labels Year, Engine size (cc), Power (hp)) plus `make`, `model`, so metadata needs no rewrite beyond dropping `license_class` and `fuel_type`; price is allowed on Wishlist only (B1 text), so book prices are dropped too; Wishlist default pins `["price"]`.

### Web (one PR, branch `feature/f018-type-refactor`, web 2.14.0)
| Task | Story | Tier | Notes |
|---|---|---|---|
| T1 | W1 icon editing: header icon is a button opening `ListIconDialog`; "Change icon" leaves the header "…" and joins the sidebar row "…" (rail where applicable) | simple | no contract change |
| T2 | W2 no-type glyph is the classic list icon; price tag leaves it | simple | after T1 (shared `icons.ts`) |
| T3 | W3 sync `api-v0.16.0`, five plural built-ins, `vehicle`/`wishlist` icons, plural hints | **complex** | waits for the backend tag |
| T4 | e2e: update affected specs, add Wishlist (price only) and icon-edit (header + sidebar) | simple | after T3 |

## Log
- 2026-10-20: planned from the user's request.
