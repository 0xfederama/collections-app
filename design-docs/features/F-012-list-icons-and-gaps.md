# F-012 — List icons + product gaps (pool item 3)

Status: **implemented** (2026-10-16, backend#25 and web#40 merged)    Release: web 2.3.0, backend 1.4.0    Roadmap: ROADMAP.md §7 item 3
Repos: backend | web    Contract: `api-v0.8.0`

## Why
Lists all look alike in the tree. Two gaps from 1.0 are still open: setting an image without saving a file first, and emptying or auto-cleaning the trash.

## Defaults chosen (to confirm)
- **Icon kinds:** an emoji, or one icon from a built-in set; no photos. Lists only, not folders. No icon means the kind's current icon.
- **Colour:** built-in icons (not emoji) can take a colour from a fixed palette of 10 named colours (theme tokens, readable in light and dark); default is the normal text colour. Stored as a name, not a hex.
- **Search:** the picker has one search box that matches icon names and emoji names/keywords (e.g. "camera", "pizza").
- **Built-in set:** the icon library the web already uses ; a curated grid of about 60 icons plus a free emoji field.
- **Trash auto-purge:** off by default; choices are Off / 7 / 30 / 90 days, one workspace setting.

## User stories
### Backend
- **F012-B1 · List icon.** As a user, I want an icon on each list. Acceptance:
  - `lists.icon` is optional text: an emoji (one grapheme) or `i:<name>` for a built-in icon key; `null` means the default. Invalid values are rejected with 422 `validation_failed`.
  - `icon_color` is optional: one of the 10 palette names, or `null`. Only allowed when `icon` is a built-in icon (422 on an emoji or no icon); it is cleared when the icon changes to an emoji or null.
  - It is set on create and via PATCH with the list's `version`. Tree, list and search responses return it.
  - Migration adds the column; existing lists stay `null`.
- **F012-B2 · Empty trash.** As a user, I want to purge the whole trash in one call. Acceptance: one endpoint (reuse the existing purge if there is one) that permanently deletes every trashed batch, idempotent, with its images removed from disk.
- **F012-B3 · Trash auto-purge.** As a user, I want old trash removed automatically if I choose. Acceptance:
  - A workspace setting `trash_retention_days` (`null` = off, the default; otherwise 1 to 365).
  - A daily job, plus once at start-up, purges batches trashed longer ago than that; it logs the count.
  - The migration test and `make test-backup` pass.
- **Contract:** `api-v0.8.0`; tag after merge. `make audit` before the `v1.4.0` tag (D-084).

### Web
- **F012-W1 · List icon picker.** As a user, I want to pick a list's icon in list settings and when creating a list. Acceptance:
  - A picker with one search box over built-in icons and emoji by name (case-insensitive, partial words), the full grid when empty, a free emoji field and "Use default".
  - For a built-in icon, a row of the 10 colour swatches (with a "None" swatch and accessible names); emoji keep their own colours and hide the swatches.
  - Emoji names/keywords come from a small vendored data file or one pinned data-only package (no runtime code); the orchestrator picks the smaller and flags it.
  - The icon shows in the tree, rail, list header and search results; same tile size and radius rules as F-008/F-009.
  - Keyboard reachable; zero serious or critical axe findings in both themes.
- **F012-W2 · Paste an image.** As a user, I want Cmd/Ctrl+V on an open item to set its image from the clipboard. Acceptance:
  - Works with a copied image or a screenshot, through the existing upload path and its size and type limits.
  - Ignored while a text field has focus and the clipboard holds text; a rejected file shows the usual error.
  - Frontend only.
- **F012-W3 · Empty trash.** A button in Trash, disabled when empty, with a confirmation that says it is permanent and how many items go.
- **F012-W4 · Auto-purge setting.** In Settings, a "Delete trash automatically" choice (Off / 7 / 30 / 90 days) with the explanation, saved immediately.
- **Release:** web 2.3.0, update the affected e2e specs and add one each for the picker, the paste and empty trash. `npm run audit` before the `v2.3.0` tag.

## Contract impact
`api-v0.8.0` (additive: `icon` and `icon_color` on lists, `trash_retention_days` in settings, the empty-trash endpoint). W1, W3, W4 pin to it; W2 needs nothing.

## Constraints
- Lean workflow D-079/D-081: Sonnet 5.5 orchestrators, workers write code only, the orchestrator runs the gate (and `make test-backup`, `npm run e2e` on a fresh `./deploy/test`) once at the end, one PR per repo, squash merge yourself.
- Keep Frosted Gallery and D-083. No new runtime dependency except at most one pinned data-only emoji-names package (flag it).

## Out of scope
Folder icons, uploaded icon images, icon packs from brands (Upkeep), TMDB.

## Repo breakdown (filled by the repo orchestrators)
### Backend (one branch `feature/F-012-list-icons-trash`, one PR, Haiku workers code only, D-079/D-081; sequential: shared spec + generated code)
- **T1 (F012-B1):** migration 000009 `lists.icon`, `lists.icon_color`; spec `icon`/`icon_color` on List create/update/summary/search/tree; validation in `internal/tree`; clear colour on icon change.
- **T2 (F012-B2):** `DELETE /api/v1/trash` empties the whole trash (204, idempotent), reusing the purge logic per batch; files removed after commit.
- **T3 (F012-B3):** migration 000010 `workspace_settings.trash_retention_days`; settings GET/PATCH; daily purge job + at start-up (logs count), like the images sweeper. Spec bumped to 0.8.0 across T1–T3.
- Final: orchestrator runs `make check` + `make test-backup` once; PR, squash merge, tag `api-v0.8.0`, `make audit`, tag `v1.4.0`.

### Web (one branch `feature/F012-list-icons-and-gaps`, one PR; Luna workers code/tests only, orchestrator validates)
- **T1 (F012-W2, first):** clipboard image on an open item through existing upload validation/errors/ETags; component coverage and real-backend paste e2e.
- **T2 (F012-W1):** after tagged `api-v0.8.0` sync, shared icon model/rendering, searchable icon/emoji picker, create + list settings, tree/rail/header/search integration, picker e2e and both-theme axe. Prefer a small vendored emoji keyword table over a package; flag the choice and measured size.
- **T3 (F012-W3/W4):** bulk empty-trash API/mocks/confirm/count and immediate retention setting using snapshot ETags and existing conflict recovery; component tests, empty-trash e2e, update affected settings coverage.
- **T4 (release):** update docs and conventions, bump web 2.3.0; orchestrator reviews FLAGS, runs `npm run check`, `npm run e2e` once against fresh parent `./deploy/test`, and `npm run audit`; one squash PR, tag `v2.3.0`, bump parent pointer and clean branch/worktree.
- Contract `api-v0.8.0` verified via backend `git ls-remote` on 2026-10-16 before contract-dependent work.

## Log
- 2026-10-16: written with defaults.

- 2026-10-16: Web F012-W1–W4 shipped in [web#40](https://github.com/0xfederama/collections-app-frontend-web/pull/40), squash `ae5fd90`, tag `v2.3.0`; pinned `api-v0.8.0`. Luna workers wrote code/tests only; orchestrator reviewed FLAGS and completed all gate stages, full unit/e2e suites with focused corrections (1300 unit tests + 1 existing skip; all 30 distinct e2e cases verified), audit clean. Picker checked in both themes at 375/1440, zero serious/critical axe, production mobile visual check; 1,323-byte local emoji table, no dependency. Parent pointer updated; branches and worktrees removed. Top-level orchestrator may close ROADMAP item 3.
