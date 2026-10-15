# F-008 — 2.x UI polish (after the first look at 2.0.0)

Status: approved (to run before pool item 3)    Release: web 2.1.0, backend 1.2.2    Roadmap: ROADMAP.md §6
Repos: web (almost all) | backend (one story)    Approved by the user: 2026-10-15

## Why
Using 2.0.0 for real showed rough edges:
- controls that don't match each other
- a cramped header area
- two "add" flows that behave the same
- missing link icons
- drag-and-drop that doesn't work
- keyboard selection that looks broken

The design direction (Frosted Gallery, D-083) stays. This round makes it consistent and finished.

The HIG notes on each story come from an Apple Human Interface Guidelines review (the `apple-design` skill). The app is a
web app, so the principles apply, not the macOS conventions.

## User stories
### Web

**Shell and navigation**

- **F008-W1 · Top bar.** As a user, I want one simple top bar with search, quick add and the theme selector, so that the
  main actions are always in the same place.
  - **Layout:**
    - Search takes most of the width, with quick add as a compact button next to it. The theme selector sits on the far
      right.
    - Quick add and the theme selector move out of their current places.
    - The sidebar loses its "Library" heading.
    - At 375 px the bar stays one row: search shrinks, quick add becomes icon-only, and the theme selector stays reachable,
      in the bar or in its overflow.
  - **HIG:**
    - `search-fields.md`: put search in the toolbar when its results show in the detail view.
    - `toolbars.md › Item groupings`: "aim for a maximum of three" groups.
    - Trade-off, `dark-mode.md`: "Avoid offering an app-specific appearance setting". You want the selector, so keep it,
      but its default is "System" and it says so.
- **F008-W2 · Sidebar "New".** As a user, I don't want a "+ New" row under the tree when the collection is empty, so that
  there's one obvious way to start. Acceptance:
  - With no folders and no lists, only the central empty-state buttons (new list, new folder) show.
  - The sidebar row appears once something exists.
- **F008-W3 · Keyboard selection and focus in the sidebar.** As a keyboard user, I want selection and focus to look right
  and stay where I expect. Acceptance:
  - Selection shows as a row highlight, not as an outline drawn around a pill.
  - After creating a folder or list with Enter, the new row is selected and focused.
  - The old selection is cleared.
  - Nothing is left with a stray ring, as in the "+ New" outline in screenshot 2.
  - Arrow keys move within the tree, and Tab moves between areas (sidebar, toolbar, content).
  - HIG: `focus-and-selection.md`: "use a focus ring for a text or search field, but use a highlight in a list or
    collection"; and "Pressing the Tab key moves focus among focus groups".
- **F008-W4 · Drag and drop works.** As a user, I want to drag a list into a folder, and drag folders and lists anywhere
  in the tree. Acceptance:
  - Dragging a list onto a folder moves it inside the folder. It's appended last, as the move rules say.
  - Dragging between rows reorders.
  - A folder that can accept the drop is highlighted only while you hover it.
  - Invalid targets show nothing: a folder can't go into itself or its descendants.
  - The dropped row stays selected.
  - Keyboard equivalents still work.
  - An e2e spec covers the move into a folder; this bug got through F-003.
  - HIG: `drag-and-drop.md › Providing feedback`: "Show people whether a destination can accept dragged content" and
    "maintain the content's selection state in the destination".

**List page**

- **F008-W5 · List header.** As a user, I want a clean list title. Acceptance:
  - The title stands alone, with no count or kind chip next to it.
  - The count moves to the end of the list (e.g. "12 items"), and is hidden when the list is empty.
  - The kind moves out of the header. Proposal: into the list's "…" menu (List settings → Kind), shown as a quiet
    subtitle only where it helps (for example in search results).
- **F008-W6 · List toolbar consistency.** As a user, I want the view options bar to look like one piece. This is the bar
  with the display modes, Sort, Pinned fields and the filter (screenshot 1). Acceptance:
  - Corner radii follow one system: the inner controls are concentric with the bar, so inner radius = outer radius minus
    the padding. No pill-shaped control sits next to rounded rectangles.
  - All controls in the bar share one style: same height, same background treatment, and a border only if the inner
    segmented buttons have one.
  - Sort and Pinned fields are the same kind of control.
  - The filter field matches.
  - A token for the radius scale is added if missing, and used everywhere else too. This applies app-wide: radii are
    always the same per level.
  - HIG: `toolbars.md › Best practices`: "ensure that its corner radius is also concentric with the bar's corners"; and
    `toolbars.md › Actions`: "Prefer system-provided symbols without borders… the section provides a visible container".
- **F008-W7 · One "new item" on an empty list.** When a list is empty, show only the centered "New item" call to action.
  The top-right one shows once the list has items.
- **F008-W8 · List description editing.** As a user, I want to click the list description to edit it in place. There's
  no pen icon next to it. Acceptance:
  - Clicking it edits it, like item fields.
  - An empty description shows a quiet "Add a description" placeholder.

**Adding items**

- **F008-W9 · Add item inside a list is inline.** As a user adding to a list, I want a new row to appear in the list and
  an empty item side page to open beside it, so that I can fill the fields and get the item saved when I'm done.
  Acceptance:
  - "New item" in a list inserts a draft row at the end and opens the side page with empty fields. The title gets focus.
  - Nothing is sent to the backend until the title is committed. The first commit creates the item; later fields save as
    usual.
  - Esc, or leaving an empty draft, removes the draft with no trace.
  - Quick add (in the top bar) stays the fast "type a title, pick a list" flow. The two flows no longer look the same.
  - HIG: `lists-and-tables.md`: "Let people edit a table when it makes sense"; `undo-and-redo.md`: cancel is free, with
    no confirmation for an empty draft.

**Item detail**

- **F008-W10 · Item title area.** As a user, I want the item's actions next to its title, not in a far corner. Acceptance:
  - The "…" menu sits right after the title, or aligned to the title row in the side page, not at the window's top-right.
  - Rework the whole title block after W1: title, kind label (D-083 put it above the title; revisit), links row, actions.
  - Deliver one coherent layout at desktop and 375 px.
  - HIG: `pull-down-buttons.md`: a menu of actions "that directly relate to the button's purpose", placed by the thing it
    acts on.
- **F008-W11 · Links row.** As a user, I want the related links on one line under the title, with "+" at the end.
  Acceptance:
  - The links (Google, IMDb, Reddit, website, streaming…) sit on one line, with the add "+" on the right. They wrap to a
    second line only when there's no room.
  - **Every link has a real icon, and all icons look the same:** same tile size, corner radius and padding, and the same
    look in light and dark.
  - Google and IMDb are monogram tiles today, because their favicons are 32 px. Fix them in this order:
    1. Restore the previous SVGs if 1.x had them.
    2. Otherwise vendor the official brand marks as SVGs from Simple Icons (CC0 paths; trademarks are used for
       identification only) and note them in `src/assets/services/README.md`.
    3. Website links use a neutral globe symbol.
    4. Any other link uses the site's favicon only if it's at least 48 px. If none of these works, flag it and propose
       an option.
  - Never fetch icons at runtime.
- **F008-W12 · Price field.** As a user, I want price to be one field that can turn into a range, not two different
  things. Acceptance:
  - One "Price" field. It shows "€ 1,200" for a single price and "€ 1,000–1,400" for a range, using the same formatting
    everywhere (a thin or normal space after the symbol, as the locale formats it).
  - Editing it shows the amount, with "Add range" (or a toggle) inside the same field that reveals a second amount.
    Removing the second amount goes back to a single price.
- **F008-W13 · Item initials as placeholders.** As a user, I want items without an image to show the first letter of
  their title, in every kind. Acceptance:
  - No tag, film or bike symbol (screenshot 3).
  - Same tile, same type, every display mode (compact, thumbnail, grid), sidebar and search results.
- **F008-W14 · Generic lists have no fields.** A generic list shows no price, nothing to add, and no pinned fields. It
  has only the title, image, website and description. This needs B1.

### Backend
- **F008-B1 · Generic has no price.** As a user, I want generic lists to have no fields at all. Acceptance:
  - Price is rejected on items in a generic list (422 `validation_failed`).
  - `price` is removed from generic's pinnable keys.
  - A migration moves any existing price on generic items into the description (the same "From 1.0"-style block as
    F-007), so nothing is lost.
  - Contract `api-v0.6.0`. Tag backend `v1.2.2` after `make audit` (D-084).

## Contract impact
`api-v0.6.0` (B1: generic loses price; small and breaking only for generic items). Web W14 pins to it. The rest of the
web stories need nothing from the backend.

## Constraints
- Lean workflow as before (D-079/D-081): Sonnet 5.5 orchestrators, workers write code only, the orchestrator runs the
  gate and the e2e suite once at the end on a fresh `./deploy/test`, one PR per repo.
- Keep the Frosted Gallery direction, D-083 and F-002's assets. Both themes keep zero serious or critical axe findings,
  and every change has a keyboard path.
- Bump the web to 2.1.0 and update the affected e2e specs. Never delete them; add the drag-into-folder spec (W4).

## Out of scope
- List icons and the product gaps (pool item 3, next).
- New kinds.

## Repo breakdown (filled by the repo orchestrators)
### Backend
| Task | Story | Branch | Worker result | Flags reviewed | PR |
| T1 spec 0.6.0 + service: reject price on generic items and lists' price pin/sort; clear price on kind change to generic | F008-B1 | `feature/F008-B1-generic-no-price` | dispatched 2026-10-15 | pending | pending |
| T2 migration 000006: generic price → "From 1.2" content block, clear price columns, strip `price` from generic pinned_fields, reset price sort; up/down test | F008-B1 | same | same worker, after T1 | pending | pending |
### Web
| Task | Story | Branch | Worker result | Flags reviewed | PR |
|---|---|---|---|---|---|
| T1 top bar (search + quick add + theme), no "Library" heading, hide sidebar "+ New" on empty tree | W1, W2 | `feature/F008-ui-polish` | dispatched 2026-10-15 | pending | pending |
| T2 sidebar keyboard selection/focus, drag and drop into folders, e2e spec | W3, W4 | same | after T1 | pending | pending |
| T3 list header, toolbar radii/consistency, empty-list CTA, description in place | W5–W8 | same | after T2 | pending | pending |
| T4 inline add item (draft row + side page) | W9 | same | after T3 | pending | pending |
| T5 item title block, links row and icons, price field, initials placeholders | W10–W13 | same | after T4 | pending | pending |
| T6 generic lists have no fields (pin `api-v0.6.0`) | W14 | same | waits for backend tag | pending | pending |

## Log
- 2026-10-15: written from the user's first look at 2.0.0 (4 screenshots), with an HIG review; inserted before pool item 3.
