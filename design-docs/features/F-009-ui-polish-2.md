# F-009 — UI polish 2 (after the look at web 2.1.0)

Status: approved    Release: web 2.2.0, backend 1.3.0    Roadmap: ROADMAP.md §6
Repos: backend | web    Approved by the user: 2026-10-16

## Why
Second polish round after the user's look at web 2.1.0.

The design direction (Frosted Gallery, D-083) stays.

## User stories
### Backend

- **F009-B1 · Price is a kind field.** As a user, I want price only on the kinds that have a price, so that generic,
  movie and TV lists don't carry a field they never use.
  Acceptance:
  - Price exists only on motorcycle, car, camera and book items. It is addable on those kinds and never shown by default.
  - Generic, movie and tv_show items have no price: a price on their items is rejected (422 `validation_failed`).
  - `price` is removed from the sortable and pinnable keys of generic, movie and tv_show.
  - A migration moves any existing price on generic, movie and tv_show items into the item's description, as a
    "From 1.0"-style Markdown block (the same as F-007/F-008), creating a content version. Nothing is lost.
  - `price` is removed from any kind's default pinned fields.
  - Contract `api-v0.7.0`. Tag backend `v1.3.0` after `make audit` (D-084). Run `make test-backup` (migration).

- **F009-B2 · Pinned fields are ordered.** As a user, I want to pick up to two pinned fields in order, so that the
  first one is the most important.
  Acceptance:
  - `pinned_fields` is an ordered list of at most two keys: the first picked is the primary, the second the secondary.
    It replaces the left/right slot model.
  - Existing pinned settings migrate with their order preserved (left → first, right → second).
  - Contract `api-v0.7.0` (shared with B1). Tag backend `v1.3.0` after `make audit` (D-084). Run `make test-backup`
    (migration).

### Web

- **F009-W1 · Item detail shows less by default.** As a user, I want the item detail to show only what matters at a
  glance, so that the page is calm and I add the rest on demand.
  Acceptance:
  - By default the item detail shows only the title, image, website and description.
  - Kind fields (including price where the kind has one) are added with "+", and only the kind's own fields are offered.

- **F009-W2 · Sort and pinned fields match the kind.** As a user, I want the sort menu and the pinned-fields picker to
  offer exactly the fields my list's kind defines, so that I never pick a field the list doesn't have.
  Acceptance:
  - "defined" = the field belongs to the list's kind. Sort and the pinned-fields picker offer exactly those fields.
  - Generic, movie and TV lists never offer price.
  - Needs B1. Pins to `api-v0.7.0`.

- **F009-W3 · Pin up to two, in order.** As a user, I want to choose up to two pinned fields in order, with no left or
  right choice, so that the first one reads as the main detail.
  Acceptance:
  - No left/right choice. The user selects up to two fields, in order.
  - First pinned field sits next to the title (to its right in compact and thumbnail, below it in grid). Second sits in
    the right corner.
  - Unpinning the first promotes the second to first.
  - Keyboard reachable.
  - Needs B2. Pins to `api-v0.7.0`.

- **F009-W4 · Move and Delete at the bottom.** As a user, I want Move and Delete at the bottom of the item side page
  instead of a "…" menu, so that they are visible where I finish reading.
  Acceptance:
  - The "…" menu on the expanded item is removed.
  - Move and Delete sit at the bottom of the item side page.
  - Delete keeps its confirmation or undo, and is reachable by keyboard.
  - Supersedes F-008 W10's "…" placement.

- **F009-W5 · One icon tile for every icon.** As a user, I want all link and streaming icons to look like one set, so
  that the page looks finished.
  Acceptance:
  - Link icons (Google, Reddit, IMDb, website) and streaming icons share the same size, shape and corner radius. No mix
    of square and round.
  - Logo is contained with even inner padding (about 15–20%), scaled to fit, never cropped or overflowing.
  - Neutral tile background in both themes.
  - Missing logos use the same letter tile, in the same style.
  - Zero serious or critical axe findings in both themes.

- **F009-W6 · Cleaner streaming row.** As a user, I want the streaming row to show just the service name, so that the
  country lives where it is set.
  Acceptance:
  - The label reads "Streaming", not "Streaming · Italy". The country comes from Settings.
  - Hover bar is slightly taller with even padding. Icons are centred vertically and horizontally.

- **F009-W7 · Centred empty Trash.** As a user, I want the empty Trash message centred in the content area, so that it
  looks deliberate.
  Acceptance:
  - The empty Trash state is centred in the content area, both ways.
  - It uses the shared empty-state layout.

- **Release (web):** web 2.2.0, `npm run audit` (D-084), tag `v2.2.0`. Update the affected e2e specs (pinned fields,
  sort, item menu). Never drop them.

## Contract impact
`api-v0.7.0`, breaking for two things: price on generic, movie and tv_show items (B1), and the pinned-fields shape (B2).
Backend first. Web W1 and W4–W7 can start before the tag. W2 and W3 pin to `api-v0.7.0`.

## Constraints and decisions already made
- Lean workflow as before (D-079/D-081): Sonnet 5.5 orchestrators, workers write code only, the orchestrator runs the
  gate and the e2e suite once at the end on a fresh `./deploy/test`, one PR per repo.
- Keep the Frosted Gallery direction, D-083 and F-002's assets. Both themes keep zero serious or critical axe findings,
  and every change has a keyboard path.
- Migrations are tested with `make test-backup` before the backend tag.

## Out of scope
- Icon packs: SVG brand packs for all link and streaming services, vendored and never fetched at runtime. Moved to
  Upkeep (later).
- List icons and product gaps (pool item 3).

## Open questions
None.

## Repo breakdown (filled by the repo orchestrators)
### Backend
| Task | Story | Branch | Worker result | Flags reviewed | PR |
|---|---|---|---|---|---|
| F009-B1+B2 (one PR) | B1, B2 | `feature/F009-price-kind-pinned-order` | done by the orchestrator directly, no worker dispatch ([DEVIATION], D-079 lean workflow); gate + `make test-backup` green | [CRUCIAL]: contract + migrations self-reviewed | [backend#24](https://github.com/0xfederama/collections-app-backend/pull/24) |
### Web
| Task | Story | Branch | Worker result | Flags reviewed | PR |
|---|---|---|---|---|---|
| T1 · ordered pinned fields + kind-matched sort/pins | W2, W3 | `feature/F009-ui-polish-2` | worker: full gate green | [CRUCIAL] contract shape reviewed (client sends only `string[] \| null`); [DECISION] `tv_show` default changed to `['seasons','streaming']` by the orchestrator so TV rows keep the service icons; `firstLetter` moved to `lib/text.ts` | pending |
| T2 · item detail shows less by default + streaming row | W1, W6 | `feature/F009-ui-polish-2` | worker: full unit suite green | [DECISION] reviewed: streaming is hidden by default like every kind field; "+ Add field" reveals a set field **read-only** and opens the editor only for an empty one (orchestrator change, with the e2e/unit tests updated) | pending |
| T3 · Move/Delete at the bottom + one icon tile set | W4, W5 | `feature/F009-ui-polish-2` | worker: targeted suites green | [DEVIATION] reviewed: the white `<rect>` and the 0.6 inset removed from `google.svg` / `imdb.svg` (the tile owns the padding now, `assets/services/README.md` records it); [DECISION] `TILE_SIZE = 36` on the item page, rows keep 20–26 px | pending |
| T4 · centred empty Trash | W7 | `feature/F009-ui-polish-2` | worker: targeted suite green; **fixed by the orchestrator after the user's screenshot** | [UNVERIFIED] worker's version centred it in the `max-w-5xl` column and floated it mid-screen; now the page drops `max-w-5xl` when empty, re-measured at 0 px offset like Home | pending |

One PR for the whole web side (D-079/D-081 lean workflow). Tasks run **sequentially on the same branch**: T2, T3 and T4 all
touch `ItemView.test.tsx` / `FieldBlock.tsx`, so they cannot be parallel. T1 is `[CRUCIAL]` (the `pinned_fields` contract
shape changed in `api-v0.7.0`). Workers run on the session's default model: no Sonnet 5.5 is available in this environment
([DEVIATION] from AGENT_WORKFLOW §2, the dispatch table assumes it).

## Log
- 2026-10-16: written from the user's look at 2.1.0; "defined" = the field belongs to the list's kind.
- 2026-10-16: backend — B1's "book" is not an item kind (the user confirmed: ignore it); price stays on motorcycle, car, camera only. B2's migration maps the old `under` slot to the primary and `right` to the secondary (the brief's "left → first"), deduping and keeping the first two.
- 2026-10-16: web — one PR for W1–W7 (D-079/D-081 lean). Three orchestrator decisions worth recording:
  - `tv_show`'s kind default is `['seasons', 'streaming']`, not the migration's `['seasons', 'episodes_per_season']`: with two pins, streaming has to stay one of them or the service icons disappear from every TV row, which nothing in F-009 asked for. Pinning seasons and episodes together still reads `5×7`.
  - W1's "+ Add field" **reveals a field that already has a value read-only**, and opens the editor only for an empty field. Dropping a user who just wants to read a saved value into an edit form (with the unsaved-changes guard) is the wrong default for "show less by default".
  - W5's letter tile reuses `firstLetter`, moved from `features/lists/ItemThumb.tsx` to `src/lib/text.ts` so `components/` does not import from `features/`.
- 2026-10-16: web — `npm run check` green (1274 tests + production image) and `npm run e2e` green (19/19) on a fresh `./deploy/test up -d --fresh`. The empty-Trash centring was additionally measured in the browser (jsdom has no layout).
- 2026-10-16: web — the user's screenshot showed the empty Trash was **not** centred: my first attempt centred it inside the page's `max-w-5xl` column and floated it in the middle of the screen. The reference is Home's empty state: centred in the whole content area, in normal flow under the heading. Fixed by dropping `max-w-5xl` when the Trash is empty (re-measured: 0 px offset, same as Home). Lesson: a bounding-box measurement that "looked plausible" was rationalised instead of compared against the reference screen — measure against the thing you are copying.
