# F-003 — Brief e2e safety net

Status: approved    Release: none (tests only, no version bump)    Roadmap: ROADMAP.md §6
Repos: backend | web    Approved by the user: 2026-10-15

## Why
The UI refresh (F-002, web 2.0.0) will rewrite every screen. A **small** set of end-to-end tests on the real stack shows
that the main flows still work after that rewrite. This is deliberately brief: a two-person app, not a test framework project.

## User stories
### Backend
- **F003-B1 · API smoke.** As the maintainer, I want one command that checks a running stack end to end over HTTP, so that
  a deploy or migration problem shows up in seconds.
  - **What it does:** `make smoke`, with `API_URL` defaulting to `http://localhost:8090`. It runs against `./deploy/test`
    and never against dev data.
  - **The flow it covers:**
    - `readyz`
    - create a folder, a list (`kind: motorcycle`) and an item with metadata and a single price
    - a kind-key sort
    - upload a small image and read its thumbnail back
    - move the item to a list of another kind, and check the move is rejected
    - search
    - trash the folder, restore it, then purge it
  - **How it behaves:**
    - It cleans up after itself.
    - It exits non-zero with a readable message.
    - It's written in Go or shell, whichever is smaller, with no new dependencies.
  - **Docs:** the backend README says when to run it: after deploy, compose or migration changes, and before a release.

### Web
- **F003-W1 · Playwright e2e.** As the maintainer, I want a few browser tests on the real backend, so that the UI refresh
  can't silently break a main flow.
  - **Setup:**
    - Add `@playwright/test` and `@axe-core/playwright`, in versions pinned per DECISIONS.
    - Chromium only.
    - `npm run e2e` runs against `./deploy/test` (`http://localhost:5183`, fresh). It's not part of `npm test` or the gate.
  - **Specs.** About 8, each short and independent, creating its own data with unique names:
    1. **Organize (AT-03).** Create a folder and a list of kind Movie. Move the list root → folder → root. Reorder lists by
       drag and by keyboard. This also restores the reorder coverage lost in F-007 (AT-21 follow-up).
    2. **Item.** Create a movie item. Fill in a kind field. Add a price, switch it to a range, then remove it. Set a
       website. Save, reload, and check the values stick. Sort by the kind key.
    3. **Description.** Edit the Markdown, preview it, save it, then restore an earlier version from history.
    4. **Image (AT-06).** Upload a JPEG and see the thumbnail. A rejected file shows its error.
    5. **Conflict (AT-09).** Two browser contexts edit the same item. The second save shows the conflict banner and keeps
       the draft.
    6. **Trash (AT-11).** Delete a folder that has content, check it's gone from the tree and search, then restore it.
    7. **Search and links (AT-12, AT-13).** Search for an item and open it from the results. Check the three external
       links: their order, the encoding, and the disabled Website button.
    8. **A11y (AT-14, reduced).** axe shows 0 serious or critical issues on Home, a list, an item and Trash, in light and
       dark, at 375 and 1440 widths only. Also check the unsaved-changes guard (AT-22).
  - **Docs:** the web README gets a short "e2e" section: how to start the stack, how to run the tests, and when to run them
    (D-076: user-flow changes and before a release).

## Contract impact
None.

## Constraints
- Same one-off lean workflow as F-007 (D-079, extended to F-003 by the user):
  - Sonnet 5.5 orchestrators.
  - Workers write the code only.
  - The orchestrator runs the gate and the new suite once at the end, on a fresh `./deploy/test`.
  - One PR per repo.
- Lean (D-034): no page-object framework, no test-data service, no visual snapshots, no CI (that's in the pool).
- Tests must be deterministic. Wait on UI states, never on `waitForTimeout`. A flaky spec gets fixed or cut before the PR.

## Out of scope
- Full AT coverage.
- Other browsers.
- The 768 and 1024 widths.
- CI.
- AT-01 (manual).

## Repo breakdown (filled by the repo orchestrators)
### Backend
| Task | Story | Branch | Worker result | Flags reviewed | PR |
|---|---|---|---|---|---|
| T1 `scripts/smoke.sh` + `make smoke` (curl+jq, shell, no new deps; shellcheck-clean) | F003-B1 | `test/F003-B1-api-smoke` | dispatched | | |
| T2 README "when to run" + CLAUDE.md command row + `docs/` | F003-B1 | same | | | |
### Web
| Task | Story | Branch | Worker result | Flags reviewed | PR |

## Log
- 2026-10-15: brief written and approved (scope set by the user: very brief, one PR per repo).
