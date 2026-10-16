# F-010 — New list: choose the folder

Status: **done** (2026-10-16)    Release: web 2.2.0 (with F-009; tag pending)    Roadmap: no own entry, shipped with F-009
Repos: web (frontend only)    Requested by the user: 2026-10-16, while reviewing web#37

## Why
Creating a list always landed at the top level, so the user had to move every new list into its folder afterwards.
The dialog should pick the folder, and remember the last choice for the session.

## User stories
### Web

- **F010-W1 · Pick the folder when creating a list.** As a user, I want the New list dialog to pick the folder, so that
  a new list lands where I am working.
  Acceptance:
  - The dialog has a folder dropdown beside Kind. Its labels are the full path, e.g. "Films › Watchlist"; Top level is
    listed first.
  - Default: the folder the dialog was opened from; else the folder the last created list went into; else Top level.
  - An explicit "New list inside X" wins over the remembered folder.
  - The remembered folder is stored in `sessionStorage` under `collection:list-folder`. It is written only after a
    successful create.
  - A stale folder id (deleted or unknown) falls back to Top level.
  - Lists only: folders are not affected.

## Contract impact
None. `folder_id` was already accepted by `POST /lists`. Frontend only.

## Constraints and decisions already made
- Session-only memory: `sessionStorage` ends with the tab and never leaves the browser (no cookie, no backend state).
- Shares the folder picker with the move flow (`DestinationPicker`).

## Out of scope
- Choosing a folder when creating a folder.
- Remembering the folder across sessions.

## Repo breakdown
### Web
| Task | Story | Branch | Worker result | Flags reviewed | PR |
|---|---|---|---|---|---|
| F010-W1 folder picker in New list | W1 | `feature/F009-ui-polish-2` (folded in) | gate green; e2e green on the fresh `./deploy/test` run | none | [web#37](https://github.com/0xfederama/collections-app-frontend-web/pull/37) (squash `80a40bb`) |

## Log
- 2026-10-16: written from the user's request while reviewing web#37. Split into its own PR (web#38) first, then folded
  into web#37 at the user's request; #38 closed and its branch deleted.
- 2026-10-16: merged in web#37 (squash `80a40bb`), with F-009 and F-011. Shipped with web 2.2.0 (tag pending).
