# F-012 — List icons + product gaps (pool item 3)

Status: **approved with defaults** (2026-10-16, user asked for the prompts; change any default before the PR merges)    Release: web 2.3.0, backend 1.4.0    Roadmap: ROADMAP.md §7 item 3
Repos: backend | web    Contract: `api-v0.8.0`

## Why
Lists all look alike in the tree. Two gaps from 1.0 are still open: setting an image without saving a file first, and emptying or auto-cleaning the trash.

## Defaults chosen (to confirm)
- **Icon kinds:** an emoji, or one icon from a built-in set; no photos. Lists only, not folders. No icon means the kind's current icon.
- **Built-in set:** the icon library the web already uses (no new dependency); a curated grid of about 60 icons plus a free emoji field.
- **Trash auto-purge:** off by default; choices are Off / 7 / 30 / 90 days, one workspace setting.

## User stories
### Backend
- **F012-B1 · List icon.** As a user, I want an icon on each list. Acceptance:
  - `lists.icon` is optional text: an emoji (one grapheme) or `i:<name>` for a built-in icon key; `null` means the default. Invalid values are rejected with 422 `validation_failed`.
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
  - A picker with the built-in grid, a field for any emoji and "Use default".
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
`api-v0.8.0` (additive: `icon` on lists, `trash_retention_days` in settings, the empty-trash endpoint). W1, W3, W4 pin to it; W2 needs nothing.

## Constraints
- Lean workflow D-079/D-081: Sonnet 5.5 orchestrators, workers write code only, the orchestrator runs the gate (and `make test-backup`, `npm run e2e` on a fresh `./deploy/test`) once at the end, one PR per repo, squash merge yourself.
- Keep Frosted Gallery and D-083. No new runtime dependency.

## Out of scope
Folder icons, uploaded icon images, icon packs from brands (Upkeep), TMDB.

## Repo breakdown (filled by the repo orchestrators)

## Log
- 2026-10-16: written with defaults.
