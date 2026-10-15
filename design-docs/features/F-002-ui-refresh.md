# F-002 — UI refresh (web 2.0.0)

Status: **approved** (2026-10-15, after the refinement rounds)    Release: web 2.0.0 (backend stays 1.x, D-080)    Roadmap: ROADMAP.md §6
Repos: web (almost all) | backend (one small story) | parent    Approved by the user: 2026-10-15

## Why
The 1.x UI works but looks like a tidy admin tool, and editing an item means a separate big form. The refresh gives the
app a layered, calm, image-forward look, makes editing direct (in the item's side page), and speeds up capture with a
Things-style quick add. Both of us use it on desktop and phone.

## Design direction (chosen with the user, 2026-10-15): Frosted Gallery
Apple's guidelines as the reference (depth, translucency, restraint), without trying to copy Liquid Glass. Not flat,
not loud. Full contract: [F-002-assets/direction-contract.md](F-002-assets/direction-contract.md). Visual reference
(open in a browser, 1440 wide), deliberately **plain**, because real lists may have no images, hidden images or dull ones. Light theme only (the dark theme follows the same materials):
[Movies](F-002-assets/frosted-gallery-movies.html) and [Motorcycles](F-002-assets/frosted-gallery-motorcycles.html) (main screens),
[Movies menus and states](F-002-assets/frosted-gallery-movies-menus.html), [Motorcycles menus and states](F-002-assets/frosted-gallery-motorcycles-menus.html)
(every menu and dialog), and the display modes: [Movies and TV](F-002-assets/frosted-gallery-movies-views.html), [Motorcycles](F-002-assets/frosted-gallery-motorcycles-views.html).
The static ✎ drawn in the main-screen and menu sketches is **wrong**: the pen shows only on hover (see decisions). Colour comes only from the accent and the (small) service logos.
- **Materials:** translucent sidebar, floating toolbar and detail sheet over the content (backdrop blur + saturate, 1 px
  hairline, inner top highlight, soft layered shadows). Blur only on those surfaces and on dialogs. Solid fallbacks under
  `@supports not (backdrop-filter)` and `prefers-reduced-transparency`.
- **Colour:** cool light grey ground with a faint ambient gradient; graphite dark theme with the same materials. One
  restrained indigo accent (about `#4F46E5`, lifted in dark) only on things you can act on. No per-list colours; the UI works
  with no images at all (neutral fallback tiles with the kind icon or initial, per the existing missing-image rule) and with dull ones.
- **Lists:** a neutral tile with the list's icon in the sidebar (per-list icons and colours stay in the pool, ROADMAP §7 #3).
- **Type:** the system font stack (SF on Apple, `system-ui` elsewhere). Fraunces, Inter and their Fontsource packages are
  removed (bundle shrinks).
- **Shape and depth:** cards radius ~18 with a 6 px inner image inset, sheets radius ~24, pill toolbar, soft layered shadows.
- **Motion:** 150–200 ms ease-out, springs only on press, everything respects `prefers-reduced-motion`.
- Exact tokens are the web orchestrator's call from the sketch, checked for contrast (glass over the lightest and darkest
  images), then recorded in `frontend-web` docs and `design-docs/UI_SPEC.md` §11.
- **Workflow for the web orchestrator:** use the `/impeccable` skill (craft the tokens and primitives first, run its finish review and `document` pass at the end), and Sonnet workers for implementation.

## User decisions already made (2026-10-15)
- **No edit mode.** Items are edited in place in the detail panel/page. Each field shows a pen top-right **only on hover (no static pen)**
  and edits with a **✓ at the end of the field to save and a ✕ to cancel** (Enter also saves, Esc cancels). The pen must also appear on keyboard focus, and on touch the field itself is tappable.
- The Markdown description is edited in place: click "No description yet" (or the text) and write. Same pattern for the list description.
- "**+ Add field**" lists the fields that aren't set (price single/range, website, kind fields).
- **Move and Delete stay in the footer and are also in a "…" menu on the item.**
- **No cents** in prices (`€1,200`). Price is **plain text** everywhere (no widgets in lists), edited with the single/range editor in the detail, and **sortable** (new sort mode "Price": ascending, items without a price last).
- **Streaming platforms as service icons**, with a `$` badge when the service offers the title only for payment. Icons for
  Netflix, Prime Video, Disney+, Apple TV+, YouTube, TIMvision and Infinity; any other service stays a text chip. The `paid`
  flag is set by hand now, TMDB fills it later (pool #4).
- **Favicon-style icons** for the services and the link buttons (Google, Letterboxd, IMDb, Reddit), all in the same uniform rounded square so they look alike. Each is the service's own favicon (netflix.com, primevideo.com, disneyplus.com, tv.apple.com, youtube.com, timvision.it, the Infinity site, and the four link sites), **downloaded once and committed as small local files**, never fetched at runtime (no third-party requests, no leak of what you watch, the prod CSP stays closed, works offline). A service whose favicon looks bad (probably Prime Video) or can't be found falls back to a monogram chip in the same square. A `researcher` picks the exact favicon sources and checks their terms.
- **Links** (a row of buttons on its own line under the title): **movies: Google, Letterboxd, IMDb; TV shows: Google, IMDb**; every other kind: Google, Reddit, Website (empty website shows "Add website"). The IMDb button opens the stored IMDb link, else a title search; Letterboxd is a title search.
- **Pinned fields** (the "quick view fields", menu "Pinned fields" next to Sort): the user picks which fields show in lists, per list, shared by both of us, with a Reset to default. Two slots: **under the title** and **on the right** (grid: both under the title). Defaults:

  | Kind | Under the title | On the right |
  |---|---|---|
  | Movie | duration (`124 min`) | streaming icons |
  | TV show | `5×7 · 45 min` (seasons × episodes, average episode duration) | streaming icons |
  | Motorcycle | displacement (`937 cc`) | price |
  | Car | year | price |
  | Camera | type (mirrorless, DSLR, film) | price |
  | Item | none | price if set |
- **Kind field changes:** motorcycle and camera lose **make and model** (they live in the title; values move into the description, nothing is lost, as in F-007); camera gains **type** (mirrorless / DSLR / film); TV show has three numbers, **seasons, episodes (per season) and average episode duration**, shown as `5×7 · 45 min` (seasons already exists; episodes and duration are new); the movie IMDb code is no longer shown as a field (the IMDb link only feeds the button).
- **All display modes** keep this layout: small icons (compact), thumbnail rows, grid.
- **Drag folders, lists and items from anywhere on the row**, no grip, with keyboard and touch equivalents.
- **List kind** is changed from a chip next to the list title only (not the Rename dialog). Changing it asks for confirmation:
  it permanently clears the kind fields of every item in the list (trashed ones too, no undo; titles, images, descriptions and history stay).
  Only asked when the list has items. Destructive confirm button.
- **Sidebar:** after the last list there is one **＋ New** button (menu: Folder or List).
- **Quick add (Things-style):** a "Quick add" button in the sidebar (and a shortcut, `N`) opens a dialog: a big title field, a
  destination list picker (defaults to the open list), and optional website, description and image. Enter adds, Esc cancels.
  It replaces the New-item dialog. The new item opens in its detail sheet.
- Keep from F-007: no "collections" wording, folder rows without arrow, no move up/down on folders, appearance toggle in the sidebar.
- **Tests stay short:** update the specs that drove the old edit form (item, AT-09 conflict, AT-22 unsaved guard) to the in-place flow; add one brief spec each for quick add and the kind-change warning. Nothing exhaustive.

## User stories
### Backend
- **F002-B1**: As the user, I want each streaming platform to say whether it is free with a subscription or paid per title, so
  that the item shows a `$` on paid services.
  Acceptance: an item's `streaming.platforms` entries can carry `paid` (boolean, default false) next to the name, with the
  existing limits (≤ 30, unique case-insensitively, name ≤ 60); existing items with plain string platforms keep working and
  read back consistently; additive first (D-expand/contract, AGENT_WORKFLOW §6); `api/openapi.yaml` updated and a tag
  `api-v0.4.0` cut; backend version 1.x minor bump only if the orchestrator judges it user-visible. The web adopts it in F002-W3.
  The backend orchestrator decides the exact shape (objects vs parallel array) and records a D-entry.
- **F002-B2**: As the user, I want the kind fields to match how I really describe things, so that lists stay light.
  Acceptance: motorcycle and camera lose `make`/`model` (migration appends their values to the item description as a "From 1.1" block, like F-007; no data lost); camera gains `camera_type` (`mirrorless` | `dslr` | `film`); TV show gains episodes per season and average episode duration (minutes); validators, sort keys (camera sort key stays), `DATA_MODEL.md`, openapi and tests updated.
- **F002-B3**: As a couple, we want to choose which fields each list pins in its rows, so that both of us see the same thing.
  Acceptance: a list stores its pinned fields (**by field key, not by a hard-coded name, so custom fields can be pinned later, ROADMAP §7 #5**) (`under` and `right` slots, an ordered subset of its kind's fields plus price and streaming); unset means the kind default; Reset clears it; version/ETag rules as for other list fields.
- **F002-B4**: As the user, I want to sort a list by price, so that I can compare what things cost.
  Acceptance: a new list sort mode `price` (ascending, no-price last, ties by title); works with the existing sort mode storage and the per-session override; openapi and tests updated.

### Web
- **F002-W1 — Foundation and shell**: As a user, I want the new look on every screen, in light and dark, so that the app feels
  like one polished product. Tokens, materials, system font stack, restyled primitives (Button, IconButton, TextField, Select,
  SegmentedControl, Menu, Dialog, Drawer, Toast, Chip, Skeleton, EmptyState, Tree), the shell (frosted sidebar, floating
  toolbar, detail sheet, mobile drawer), Home, Search, Trash and Settings restyled.
  Acceptance: both themes at zero axe violations, solid fallbacks work, bundle no larger than 1.1.0 (fonts removed), phone and desktop checked in a browser.
- **F002-W2 — Lists and sidebar behavior**: all three display modes (small icons, thumbnail rows, grid; rows are the likely everyday view) restyled with the pinned-fields layout (under the title / on the right); the **Pinned fields** menu (after F002-B3) and **Sort by price** (after F002-B4); the single **＋ New** button; drag from anywhere (folders, lists,
  items) with keyboard and long-press touch; list header tidied with the kind chip next to the title and the irreversible-clear
  confirmation (no kind picker in Rename); list description edited in place; sidebar "…" menus on hover/focus (always visible on touch).
  Acceptance: reorder works by mouse, touch and keyboard; clicking a row still navigates; kind change shows the warning only for lists with items.
- **F002-W3 — Item detail in place**: no edit mode; per-field pens with ✓/✗; description edited in place with its own version and
  History; "+ Add field"; change the image from the image; Move/Delete in footer and "…" menu; imageless hero collapses to an
  "Add image" affordance; no "No website" button; quieter timestamps; no-cents price; streaming service icons with `$`
  (after F002-B1); the links row (movies: Google, Letterboxd, IMDb; TV shows: Google, IMDb; otherwise Google, Reddit, Website) with favicon-style icons; kind field changes (after F002-B2); per-field 412 conflict (draft kept, Copy draft, Reload latest); leaving with an open field asks or saves.
  Acceptance: AT-09 and AT-22 specs updated to this flow, all item fields editable without a form, conflict keeps the draft.
- **F002-W4 — Quick add**: the dialog above, global button + `N` shortcut, destination picker, optional website, description
  and image, replaces the New-item dialog. Acceptance: one brief spec; Enter adds with only a title; the item opens in its sheet.
- **F002-W5 — Close-out**: update `UI_SPEC.md` and the web docs/README/CLAUDE.md for the new system (via `docs-keeper`), run the
  full gate and the F-003 e2e, `DESIGN.md` written by the impeccable documenter.

### Parent / ops (top-level orchestrator)
- Pointer bumps, STATUS.md and ROADMAP.md rows, `UI_SPEC.md` pointer to the new design, tag `web 2.0.0` after the PRs merge.

## Contract impact
Four backend stories, one backend PR, one contract tag (`api-v0.4.0` or higher): **B1** paid flag on streaming platforms, **B2** kind field changes plus migration, **B3** pinned fields per list, **B4** price sort mode. **Backend before** the web stories that use them: B1 and B2 before F002-W3, B3 and B4 before the matching parts of F002-W2. W1 and W4 do not need it, so they can start at once. Everything else uses the existing API (`PATCH /items/{id}` and the
separate content endpoint already exist; the web orchestrator confirms per-field PATCH works with `If-Match`).

## Constraints and decisions already made
Lean (D-034, no heavy UI kits), accessibility holds (D-030 both themes, WCAG 2.2 AA intent, keyboard equivalents for in-place
editing and drag), API never exposed publicly. **One PR per orchestrator** (the user's rule for this feature): one web PR with all
web stories, one backend PR; workers commit to the story branch and the orchestrator opens the PR and merges it (D-077).

## Out of scope
**Custom fields and custom types** (ROADMAP §7 #5, next after this feature): this feature only keeps the door open (pinned fields stored by key, kind validators stay a registry).

List icons (pool #3), TMDB and automatic `paid` filling (pool #4), image paste, empty-trash, user-defined kinds, new screens, any
other behavior change not listed above.

## Open questions
| ID | Question | Default |
|---|---|---|
| F002-Q1 | Which favicon source per service, and their terms? | The service's own favicon, committed locally; `researcher` checks; monogram fallback |
| F002-Q2 | Quick-add shortcut `N` conflicts with typing in fields? | Active only when focus isn't in an input |
| F002-Q4 | TV episodes: per season (same count each season) or total? | Per season, plain integers |
| F002-Q3 | Does `PATCH /items/{id}` accept a single field with its own ETag? | Web orchestrator confirms; if not, a tiny backend story |

## Repo breakdown (filled by the repo orchestrators)
### Backend
| Task | Story | Branch | Worker result | Flags reviewed | PR |
|---|---|---|---|---|---|
### Web
| Task | Story | Branch | Worker result | Flags reviewed | PR |
|---|---|---|---|---|---|

## Log
- 2026-10-15: final round: favicon-style local icons, TV links Google + IMDb only, TV triple seasons/episodes/duration; custom fields and types recorded in the roadmap; brief **approved**.
- 2026-10-15: refinement round: pen on hover only, ✓ at the end of the field, links per kind (TV like movies), real logos, pinned fields (two slots) with kind defaults, price text and sortable, kind field changes, display-mode sketches. Backend stories B2 to B4 added.
- 2026-10-15: design direction **Frosted Gallery** chosen by the user (Apple-style reference, layered and soft); non-visual changes and decisions agreed in chat; brief written.
