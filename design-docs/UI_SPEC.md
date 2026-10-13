# UI Spec

The app should feel like a **polished collection product**: image-forward, calm, and tactile. It must not look like
an admin dashboard. Visual quality is an MVP requirement.

## 1. Routes

| Route | Screen |
|---|---|
| `/` | Home: recently updated items (12) and quick links to lists. Empty state guides the user to create a first list |
| `/lists/:listId` | List view |
| `/lists/:listId/items/:itemId` | List view and item detail (side panel ≥ 1280 px, full page below) |
| `/search?q=` | Search results |
| `/trash` | Trash |
| `/settings` | Settings |

URL state: list sort override and filter go in query params (`?q=`). Expanded folders and the sidebar collapsed state persist in `localStorage`.
Navigating back from an item restores the list scroll position and the selected list.

## 2. Layout & responsive behavior

| Breakpoint | Layout |
|---|---|
| < 768 px (mobile) | Top bar with menu button → sidebar as a **drawer**. Item detail and forms are **full-screen**. Grid has 2 columns |
| 768–1023 (tablet) | Collapsible sidebar (icon rail ↔ full). Detail is a full page. Grid has 3 columns |
| 1024–1279 (desktop) | Persistent sidebar (280 px, resizable 220–400). Detail is a full page. Grid has 3–4 columns |
| ≥ 1280 (wide) | Persistent sidebar, main area, and **detail panel** (min 420 px) beside the list. Grid uses auto-fill, min 220 px |

Sidebar contents: workspace name, global search field (`/` shortcut focuses it), the folder/list tree
(expand/collapse, item counts, a "+" menu for new folder or list, a context menu with rename/move/delete), then Trash
and Settings at the bottom.

## 3. List view

Header: breadcrumbs (`Folder › Sub › List`), name, description (expandable), item count, **Add item**, the
display mode segmented control (compact / thumbnail / grid, icons with labels for assistive tech), sort select (Manual / Title / Recently updated),
filter field, and an overflow menu (rename, edit description, move, delete).

| Mode | Rendering |
|---|---|
| `compact` | Dense rows: 40 px square thumb, title, status chip, price, kind icon |
| `thumbnail` | Rows: 96 px 4:3 thumb, title, summary (2 lines clamp), status chip, price |
| `grid` | Cards: 4:3 cover image (object-fit cover, center), title (2 lines), price, status chip, kind badge |

- **Drag handles** appear only in Manual sort with no active filter. Otherwise the handle is hidden and a hint explains why. The keyboard alternative is dnd-kit's keyboard sensor with live-region announcements. A "Move up/down" menu entry is the fallback.
- **Missing image:** a soft tinted tile with the kind icon and the title's first letter. It never shows a broken-image glyph. External URL images that fail to load fall back to the same tile.
- **Status chip:** text is always shown, never color alone.
- Price formatting uses `Intl.NumberFormat` with the item currency: `€1,299` or `€1,200–1,500`. The locale is the browser's.

## 4. Item detail

View mode, top to bottom:
1. Hero image (max 16:9 viewport-limited, click → lightbox with original) or the fallback tile.
2. Title, kind badge, status chip, price.
3. **Three link buttons** (PRODUCT §9): Google · Reddit · Official site (disabled with label when absent).
4. Summary.
5. Kind section: a compact definition grid of the set fields with units (e.g. `937 cc`, `111 hp`, `24.2 MP`), hidden entirely when none are set. For movies and TV shows: IMDb link and streaming platforms with the country label, plus a warning if the country differs from settings. TV show shows `2019–2023` or `2019–present`. Kind icons: generic = tag, movie = film, TV show = tv, motorcycle = motorbike, car = car, camera = camera.
6. Description: rendered Markdown, with a "History" button.
7. Footer: created/updated timestamps, plus Move, Delete.

**Edit** switches to a form with sections: *Basics* (title, kind, summary, status, price min/max + currency,
official URL) · *Image* · *Kind details* · *Description* · *Organization* (move to list).

- Image section: dropzone ("Drop an image or **browse**"), accepts `image/jpeg,image/png,image/webp`, client-side checks for size (10 MiB) and type with clear messages (the server is authoritative). Alternatively, "Use image URL" with a text field. Also *Remove image*. Shows upload progress, and the image change is **its own request** (applied immediately, not part of the form save) with its own success or error toast.
- Description: CodeMirror 6 Markdown source editor with **Edit / Preview** tabs. Saved independently of the Basics form with its own Save button and its own version (independent conflict handling).
- Save button shows a pending spinner and is disabled while pending (no double submit). On success, show a toast and stay in view mode.
- **Unsaved changes guard:** React Router `useBlocker` plus `beforeunload` → dialog "Discard changes?"
- Kind change shows an inline warning: "Switching kind clears the <kind> details." Only when some are set.
- Kind detail fields are rendered from one per-kind field config (`features/items/kinds/*.ts`: key, label, input type, unit, enum options with labels) that mirrors DATA_MODEL §2.1, so adding a kind is one config file plus generated types. Enum fields use a Select, numbers use numeric inputs with units as suffixes, and the whole section is optional.
- Price: decimal input, max 2 decimals. If `max` is entered without `min`, the label shows "up to". Currency select defaults to the settings currency.

**History panel** (drawer): versions newest first with relative time and size. Selecting one shows a read-only preview with a *Restore this version* button and confirmation. Restore uses the current content ETag.

## 5. Create flows

- New folder / new list: a small dialog with name (and parent preselected from context).
- New item: a dialog with title (required) and kind. After creation it opens the detail in edit mode.
- Move dialog: a tree picker with invalid destinations (self, descendants, current parent, trashed) **disabled** with a reason tooltip.

## 6. Search

The global field shows a dropdown of the top 8 results after 250 ms debounce (≥ 1 char), and Enter goes to `/search?q=`.
A result row shows thumb, title, and path breadcrumb. Keyboard: arrow keys and Enter, with Esc to close. An empty result shows a friendly message.

## 7. Trash

A table/list of entries with icon, name, type, former path, deleted time, and counts.
Actions: **Restore** (if not `restorable_in_place`, the button becomes "Restore to…" and explains why, e.g. *"Parent folder 'Bikes' is in Trash"*,
offering "Restore 'Bikes' instead" or opening the destination picker) and **Delete permanently** (confirmation states counts and that
nested trashed entries are included; type-to-confirm is not required).

## 8. Settings

Fields: **theme** (System / Light / Dark segmented control, stored per device in `localStorage`, applied instantly, no ETag), workspace name, streaming country (searchable select of ISO countries), default currency (searchable ISO 4217), and history limit (0–200).
Uses the same save/conflict behavior as items.

## 9. Conflict & error UX (mandatory)

**Version conflict (412)** on any save:
- The form stays in edit mode with **all draft values intact**.
- A banner (role=alert) reads: *"Someone else changed this item while you were editing. Your changes have not been saved."*
- **Copy my draft** copies a readable text dump of all changed fields plus the Markdown to the clipboard and confirms with a toast. If the Clipboard API fails, it opens a dialog with a read-only selectable `<textarea>`.
- **Reload latest** opens a confirmation dialog: *"Replace your unsaved changes with the latest version?"* Confirming loads fresh data and leaves edit mode.
- No auto-merge and no auto-retry.

**Network/5xx error:** an inline error with **Retry**. The draft is preserved, and it is **not** described as a conflict.
**422:** field errors mapped to fields via `errors[].field`, with the first invalid field focused.
**409 order_stale:** roll back the optimistic order, refetch, and show a toast: "List changed, order refreshed."

## 10. UI states

Every data view defines **loading** (skeletons that match the final layout, no spinners for full views), **empty**
(illustrative icon, one sentence, primary action), **error** (message plus Retry), and **disabled** states. Hover, focus,
active, and destructive variants are defined for every interactive primitive.

## 11. Design system

Tokens live in `src/styles/tokens.css` as CSS custom properties, mapped into Tailwind's theme. **Light and dark themes are both MVP** (D-030).
Components only use semantic tokens (`--bg`, `--surface`, `--text`, `--text-muted`, `--border`, `--accent`, …), never raw palette values.
Theme resolution: the `localStorage` choice, else `prefers-color-scheme`. It is applied as `data-theme` on `<html>` by an inline script in `index.html` **before first paint** (no flash), and `color-scheme` is set accordingly.

**Typography** (self-hosted via Fontsource):
- UI/body: **Inter** (variable), with `font-feature-settings: "cv11","ss01"` and tabular numbers for prices.
- Display (list titles, item titles in detail, empty-state headings): **Fraunces** (variable, soft optical sizing), used sparingly.
- Scale (rem): 0.75 / 0.875 / 1 (base, 16 px) / 1.125 / 1.25 / 1.5 / 2 / 2.5. Line height 1.5 for body and 1.2 for display.

**Spacing:** 4 px base, with the scale 4, 8, 12, 16, 20, 24, 32, 40, 48, 64.

**Radii:** `--radius-sm` 6 px (chips, inputs), `--radius-md` 10 px (buttons, menus), `--radius-lg` 16 px (cards, panels), `--radius-xl` 24 px (dialogs, hero image), and full (pills, avatars).

**Color** (warm neutral with one accent):
- Neutrals: warm stone scale (e.g. `#FAFAF9` background, `#FFFFFF` surface, `#E7E5E4` border, `#78716C` muted text, `#1C1917` text).
- Accent: one confident hue (proposal: deep teal `#0F766E` / hover `#115E59`), used for primary actions, focus, and selection.
- Semantic: success, warning, and danger, each with tinted background, border, and text variants.
- Dark theme: warm near-black surfaces, not pure black (e.g. `#0C0A09` background, `#1C1917` surface, `#292524` raised, `#44403C` border, `#A8A29E` muted text, `#FAFAF9` text). The accent is lightened for contrast (e.g. teal `#2DD4BF` for text, links, and focus; primary buttons `#14B8A6` with dark text). Shadows are mostly replaced by borders and lighter raised surfaces.
- Images in dark mode are not dimmed. Fallback tiles use dark-theme tints.
- Contrast: body text ≥ 4.5:1, large text and UI boundaries ≥ 3:1, **in both themes**. CI checks this with axe in e2e.

**Surfaces & elevation:** cards are a white surface with a 1 px border (`--border`) and `--shadow-sm` (`0 1px 2px rgb(28 25 23 / .06)`). On hover they lift to `--shadow-md` with a 150 ms transform `translateY(-1px)`. Dialogs and menus use `--shadow-lg`. A backdrop blur is optional.

**Focus:** a 2 px accent focus ring with a 2 px offset, `:focus-visible` only, and it is never removed.

**Motion:** 150–200 ms ease-out for hover, menus, and drawers. The detail panel slides in. Everything respects `prefers-reduced-motion`.

**Images:** grid covers 4:3, thumbnail rows 4:3, compact 1:1, all `object-fit: cover` with `loading="lazy"` and `decoding="async"`. External images use `referrerpolicy="no-referrer"`. Uploaded images use the `thumbnail_url` in lists and the original only in detail and lightbox.

**Primitives** (in `components/ui`, each with all states): Button (primary / secondary / ghost / danger; sm / md), IconButton (always has `aria-label`), TextField, TextArea, Select / Combobox, SegmentedControl, Menu, Dialog / AlertDialog, Drawer, Tooltip, Toast, Chip, Badge, Card, Skeleton, EmptyState, Breadcrumbs, Tree.

## 12. Accessibility (MVP requirements)

- WCAG 2.2 AA intent. Every interactive element is keyboard-reachable in a logical order, with focus visible and no keyboard traps (dialogs trap focus correctly and restore it on close).
- Landmarks: `nav` (sidebar), `main`, and `aside` (detail panel). The sidebar tree follows the ARIA tree pattern.
- All icon-only buttons are labeled. Images have alt text: the item title, or empty for decorative fallback tiles.
- Live regions announce drag-and-drop moves, toasts, and save results.
- No information is conveyed by color alone. Tap targets are ≥ 44×44 px on touch.
- Playwright plus axe has zero serious or critical violations on every route (ACCEPTANCE_TESTS AT-14).
