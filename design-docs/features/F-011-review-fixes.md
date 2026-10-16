# F-011 — Review fixes on web#37

Status: **done** (2026-10-16)    Release: web 2.2.0 (with F-009; tag pending)    Roadmap: no own entry, shipped with F-009
Repos: web (frontend only)    Requested by the user: 2026-10-16, while reviewing web#37

## Why
The user's review of web#37 (F-009 and F-010) found rough edges in the new screens: a country field that repeats
Settings, a platforms field that is hard to fill, hover and focus paint that doubles up, and a folder control that
doesn't match the rest of the dialog.

## User stories
### Web

- **F011-W1 · No country on the item's streaming editor.** As a user, I want the streaming editor to show only the
  service, so that the country lives in Settings.
  Acceptance:
  - The item's streaming editor has no country field.
  - The contract still requires `metadata.streaming.country`, so the draft sends the item's own country or the Settings
    one. If neither is set, the message is "Pick a streaming country in Settings first."
- **F011-W2 · Platforms as a multi-choice dropdown.** As a user, I want to pick platforms from a list, so that the
  common services are one click away.
  Acceptance:
  - A multi-choice dropdown over the services we ship logos for.
  - A field to type a service we don't ship a logo for.
- **F011-W3 · Tree row "…" has no hover of its own.** As a user, I want the row's "…" button to hover with the row, so
  that there is no second box drawn over it.
  Acceptance:
  - The "…" paints no hover fill of its own; the row's hover is the only one.
- **F011-W4 · Field pen shares the row hover.** As a user, I want the field pen to hover with its row and its field
  name to line up with the value, so that the field reads as one row.
  Acceptance:
  - The pen shares the row's hover background.
  - The field name lines up with its value.
- **F011-W5 · "+ New" uses the inset focus ring.** As a user using the keyboard, I want the "+ New" focus ring to be
  visible, so that I can see where focus is.
  Acceptance:
  - "+ New" uses the repo's inset focus ring. The outer ring was clipped by the scroll container.
- **F011-W6 · Folder as a dropdown beside Kind.** As a user, I want the folder control to sit beside Kind, so that the
  New list dialog reads as one form.
  Acceptance:
  - The folder is a dropdown beside Kind, labelled with the full path. Same control as F-010-W1.

## Contract impact
None. Frontend only; the streaming country is still sent as the contract requires.

## Constraints and decisions already made
- Keep the Frosted Gallery direction (D-083) and the repo's focus-ring and hover tokens.
- Every change keeps a keyboard path.

## Out of scope
- Reading the streaming country from anywhere else than the item or Settings.

## Known follow-up
- `STREAMING_SERVICES` in `src/components/ServiceIcon.tsx` is hand-maintained and not derived from `serviceEntries`.
  The two can drift; a future change should derive one from the other.

## Repo breakdown
### Web
| Task | Story | Branch | Worker result | Flags reviewed | PR |
|---|---|---|---|---|---|
| F011-W1..W6 review fixes | W1–W6 | `feature/F009-ui-polish-2` (folded in) | gate green (1281 tests + image); e2e 21/21 on a fresh `./deploy/test` | none recorded | [web#37](https://github.com/0xfederama/collections-app-frontend-web/pull/37) (squash `80a40bb`) |

## Log
- 2026-10-16: written from the user's review of web#37. Merged in web#37 (squash `80a40bb`), with F-009 and F-010.
  Shipped with web 2.2.0 (tag pending).
- 2026-10-16: e2e note from the run: the drag specs can fail on the first run after `./deploy/test up -d --fresh`
  (the Vite dev server compiles on the first request); they pass on a warm run.
