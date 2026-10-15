# F-007 — Lists and items restructure

Status: draft (stories are completed after the exploration session)    Release: 1.1    Roadmap: ROADMAP.md §6
Repos: backend | web | parent    Approved by the user: —

## Why
The 1.0 model is more general than the way the app is used: lists mix item types, and each type comes with a long set of
predefined fields. Reshaping it now, before the e2e tests (F-003) and the UI refresh (F-002), means both are built once on
the final model.

## Known scope (from the user, 2026-10-15)
- **One item type per list.** A list has one kind, chosen at creation; every item in it is of that kind. Item forms stop
  asking for a kind.
- **Fewer predefined fields** per kind (today: PRODUCT §4.2, DATA_MODEL §2.1). Which fields stay is decided with the user.
- **List description:** Markdown on a list, e.g. for links that apply to all its items.
- Issues found in the exploration session on `./deploy/test --fresh` (to be added here).

## User stories
To be written after the exploration session.

## Contract impact
Expected: breaking for items/lists (`api-v0.3.0`): list `kind` and `description`, item `kind` derived from its list, smaller
per-kind metadata. Backend stories merge and get tagged before the web stories that use them.

## Constraints and decisions already made
- Never lose user data: the migration keeps every existing item and its values (dropped fields are kept somewhere
  recoverable, or the user explicitly agrees they can go).
- Per-kind validator registry and `metadata` JSONB stay (ARCHITECTURE §7); TMDB (2.0) must still fit.
- Lean (D-034), optimistic concurrency (D-012-style `version`) on anything editable.

## Out of scope
- List import (pool, defined later).
- Visual design (F-002).

## Open questions
| ID | Question | Default |
|---|---|---|
| F007-Q1 | Existing lists that mix kinds: how are they migrated? | Split into one list per kind in the same folder ("<name> · Movies"), nothing deleted |
| F007-Q2 | Which fields stay per kind? | Decided with the user after the exploration session |
| F007-Q3 | Can a list's kind change later? | Yes, with the same warning as today's item kind change (kind fields are cleared); free if the list is empty |
| F007-Q4 | Does the list description get version history like item descriptions? | Yes, reusing the item content/version mechanism |
| F007-Q5 | Is there still a "generic" kind for anything-goes lists? | Yes ("Item") |

## Repo breakdown (filled by the repo orchestrators)
### Backend
| Task | Story | Branch | Worker result | Flags reviewed | PR |
### Web
| Task | Story | Branch | Worker result | Flags reviewed | PR |

## Log
- 2026-10-15: draft created from the user's re-plan; stories wait for the exploration session.
