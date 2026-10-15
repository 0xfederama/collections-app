# F-002 — UI refresh (web 2.0.0)

Status: **draft** (direction picked 2026-10-15, design still being refined with the user; do not start the repo orchestrators)    Release: web 2.0.0 (backend stays 1.x, D-080)    Roadmap: ROADMAP.md §6
Repos: web (almost all) | backend (one small story) | parent    Approved by the user: not yet

## Why
The 1.x UI works but looks like a tidy admin tool, and editing an item means a separate big form. The refresh gives the
app a layered, calm, image-forward look, makes editing direct (in the item's side page), and speeds up capture with a
Things-style quick add. Both of us use it on desktop and phone.

## Design direction (chosen with the user, 2026-10-15): Frosted Gallery
Apple's guidelines as the reference (depth, translucency, restraint), without trying to copy Liquid Glass. Not flat,
not loud. Full contract: [F-002-assets/direction-contract.md](F-002-assets/direction-contract.md). Visual reference
(open in a browser, 1440 wide), deliberately **plain**, because real lists may have no images, hidden images or dull ones:
[rows, no images, quick add open](F-002-assets/frosted-gallery-rows-no-images.html) (the likely everyday view),
[grid with fallback tiles](F-002-assets/frosted-gallery-grid-fallback-tiles.html),
[grid with dull photos](F-002-assets/frosted-gallery-grid-dull-photos.html) and
[dark theme](F-002-assets/frosted-gallery-dark-rows.html). Colour comes only from the accent and the (small) streaming logos.
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
- **No edit mode.** Items are edited in place in the detail panel/page. Each field shows a pen top-right on hover and edits
  with **explicit ✓ / ✗ buttons** (Enter also saves, Esc cancels). The pen must be focusable, and on touch the field itself is tappable.
- The Markdown description is edited in place: click "No description yet" (or the text) and write. Same pattern for the list description.
- "**+ Add field**" lists the fields that aren't set (price single/range, website, kind fields).
- **Move and Delete stay in the footer and are also in a "…" menu on the item.**
- **No cents** in prices (`€1,200`).
- **Streaming platforms as service icons**, with a `$` badge when the service offers the title only for payment. Icons for
  Netflix, Prime Video, Disney+, Apple TV+, YouTube, TIMvision and Infinity; any other service stays a text chip. The `paid`
  flag is set by hand now, TMDB fills it later (pool #4).
- **Drag folders, lists and items from anywhere on the row**, no grip, with keyboard and touch equivalents.
- **List kind** is changed from a chip next to the list title only (not the Rename dialog). Changing it asks for confirmation:
  it permanently clears the kind fields of every item in the list (trashed ones too, no undo; titles, images, descriptions and history stay).
  Only asked when the list has items. Destructive confirm button.
- **Quick add (Things-style):** a "New item" button in the sidebar (and a shortcut, `N`) opens a dialog: a big title field, a
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

### Web
- **F002-W1 — Foundation and shell**: As a user, I want the new look on every screen, in light and dark, so that the app feels
  like one polished product. Tokens, materials, system font stack, restyled primitives (Button, IconButton, TextField, Select,
  SegmentedControl, Menu, Dialog, Drawer, Toast, Chip, Skeleton, EmptyState, Tree), the shell (frosted sidebar, floating
  toolbar, detail sheet, mobile drawer), Home, Search, Trash and Settings restyled.
  Acceptance: both themes at zero axe violations, solid fallbacks work, bundle no larger than 1.1.0 (fonts removed), phone and desktop checked in a browser.
- **F002-W2 — Lists and sidebar behavior**: card/row/grid views (rows are the likely everyday view) restyled; drag from anywhere (folders, lists,
  items) with keyboard and long-press touch; list header tidied with the kind chip next to the title and the irreversible-clear
  confirmation (no kind picker in Rename); list description edited in place; sidebar "…" menus on hover/focus (always visible on touch).
  Acceptance: reorder works by mouse, touch and keyboard; clicking a row still navigates; kind change shows the warning only for lists with items.
- **F002-W3 — Item detail in place**: no edit mode; per-field pens with ✓/✗; description edited in place with its own version and
  History; "+ Add field"; change the image from the image; Move/Delete in footer and "…" menu; imageless hero collapses to an
  "Add image" affordance; no "No website" button; quieter timestamps; no-cents price; streaming service icons with `$`
  (after F002-B1); per-field 412 conflict (draft kept, Copy draft, Reload latest); leaving with an open field asks or saves.
  Acceptance: AT-09 and AT-22 specs updated to this flow, all item fields editable without a form, conflict keeps the draft.
- **F002-W4 — Quick add**: the dialog above, global button + `N` shortcut, destination picker, optional website, description
  and image, replaces the New-item dialog. Acceptance: one brief spec; Enter adds with only a title; the item opens in its sheet.
- **F002-W5 — Close-out**: update `UI_SPEC.md` and the web docs/README/CLAUDE.md for the new system (via `docs-keeper`), run the
  full gate and the F-003 e2e, `DESIGN.md` written by the impeccable documenter.

### Parent / ops (top-level orchestrator)
- Pointer bumps, STATUS.md and ROADMAP.md rows, `UI_SPEC.md` pointer to the new design, tag `web 2.0.0` after the PRs merge.

## Contract impact
F002-B1 only: additive change to the item `metadata.streaming.platforms` entries, tag `api-v0.4.0`, **backend before F002-W3**
(W1, W2, W4 do not need it, so they can start at once). Everything else uses the existing API (`PATCH /items/{id}` and the
separate content endpoint already exist; the web orchestrator confirms per-field PATCH works with `If-Match`).

## Constraints and decisions already made
Lean (D-034, no heavy UI kits), accessibility holds (D-030 both themes, WCAG 2.2 AA intent, keyboard equivalents for in-place
editing and drag), API never exposed publicly. **One PR per orchestrator** (the user's rule for this feature): one web PR with all
web stories, one backend PR; workers commit to the story branch and the orchestrator opens the PR and merges it (D-077).

## Out of scope
List icons (pool #3), TMDB and automatic `paid` filling (pool #4), image paste, empty-trash, user-defined kinds, new screens, any
other behavior change not listed above.

## Open questions
| ID | Question | Default |
|---|---|---|
| F002-Q1 | Where do the service icons come from (licensing, weight)? | Small local SVG set (7 services), checked by a `researcher`; text chip fallback |
| F002-Q2 | Quick-add shortcut `N` conflicts with typing in fields? | Active only when focus isn't in an input |
| F002-Q3 | Does `PATCH /items/{id}` accept a single field with its own ETag? | Web orchestrator confirms; if not, a tiny backend story |

## Repo breakdown (filled by the repo orchestrators)
### Backend
| Task | Story | Branch | Worker result | Flags reviewed | PR |
|---|---|---|---|---|---|
### Web
| Task | Story | Branch | Worker result | Flags reviewed | PR |
|---|---|---|---|---|---|

## Log
- 2026-10-15: design direction **Frosted Gallery** chosen by the user (Apple-style reference, layered and soft); non-visual changes and decisions agreed in chat; brief written.
