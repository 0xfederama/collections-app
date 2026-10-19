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

## Defaults chosen (to confirm)
- **Camera is not a built-in any more.** Existing camera lists become a **custom type "Cameras"** (make, model, release year, sensor format, megapixels, price allowed), so no data is lost; the user can delete it later like any custom type.
- **Motorcycle and Car lists become Vehicles.** make, model, model year, displacement and power map to the Vehicles fields. Fields Vehicles does not have (licence class, fuel type) and **prices** (price now lives on Wishlist and custom types) are moved into the item's description as a "From the old type" Markdown block, as F-007 did; nothing is dropped silently. A custom type or a list with a mix is handled per list by its old type.
- **Built-ins stay locked** (cannot be deleted or have fields removed), as in F-014. Choosing which built-ins are *shown* is not part of this round.
- **Existing labels:** `type_name` and the type labels become plural by migration; `Runtime` etc. unchanged.

## User stories
### Backend
- **F018-B1 · Built-in set.** Migration: add `vehicle` and `wishlist` definitions (fields, default pins, default icons `car` and `tag`, price allowed on Wishlist only among built-ins); pluralise the labels of the remaining built-ins; convert camera into the custom type "Cameras"; convert motorcycle and car into `vehicle` with the field mapping and the description block above; reversible where possible, idempotent, tested on a fixture with every old type filled; `make test-backup`. The seed function is replaced, not renamed (as in F-014 #33). A custom type whose key collides with the new keys is handled without data loss and flagged.
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
| F018-Q1 | Does Vehicles allow a price | No; old prices go to the description |
| F018-Q2 | Camera | Becomes the custom type "Cameras" |
| F018-Q3 | Extra Vehicles fields (fuel type, licence class) | Dropped from the type, kept in the description |

## Repo breakdown (filled by the repo orchestrators)

## Log
- 2026-10-20: planned from the user's request.
