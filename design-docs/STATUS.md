# Status Board

Living progress tracker shared by every session (AGENT_WORKFLOW §7). **Re-read right before editing**, change only your
own rows, and use dates. Task IDs and dependencies are in [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md).

States: `todo` · `in progress` · `in review` (PR open) · `blocked` · `done` (PR merged)

## Now: workflow v2 (from 2026-10-15, D-074)

**v1.0.0 is tagged** (backend `ea0b1c5`, web `2b9e7a6`, parent). Roadmap: [`ROADMAP.md`](../ROADMAP.md).
Feature briefs: [`features/`](features/). Repo orchestrators add their task rows under their feature.

| Feature | Story | Owner | State | Branch | PR | Updated | Notes |
|---|---|---|---|---|---|---|---|
| F-019 | Backend architecture refactor (B0..B5) | backend orch. | **DONE 2026-10-31**: B1-B5b + B6 merged (backend#51-#64), tags `api-v1.0.0` (contract, generated) and **`v2.6.0`** (backend release; `make check`, `make test-backup`, `make smoke`, `make audit` clean; final `/code-review` medium pass fixed in #64). Go 1.27.3. **Open for the user/top-level orch.: reset the dev DB, then bump the parent backend pointer (to `v2.6.0`); record DECISIONS/ARCHITECTURE/DATA_MODEL updates (see the contract report and B0 report); web adopts `api-v1.0.0` (F020-W6).** Not done: separate `/simplify` pass (the review's cleanup angles covered reuse/simplification/efficiency), spike branch `refactor/F019-B0-spike` can be deleted | | | 2026-10-31 | [brief](features/F-019-backend-architecture.md); [contract report](features/F-019-contract-report.md); tasks in features/F-019-tasks/; D-106 |
| F-020 | Web architecture refactor (W1..W6) | web orch. | **done 2026-10-31**: W1-W6 (web#81-#92, main `08add56`), web `v2.18.0` tagged on `api-v1.0.0` | | | 2026-10-21 | [brief](features/F-020-web-architecture.md); W1 (links) can start now |
| F-018 | F018-B1..B2 type refactor backend (one PR: migration 000025, `api-v0.16.0`, release `v2.5.0`) | backend orch. | **done** 2026-10-20: squash `35ef67e`, tags `api-v0.16.0` + `v2.5.0`, `make check`, `make test-backup`, `make audit` clean; web syncs to `api-v0.16.0`; branch and worktree deleted | `feature/F018-type-refactor` (deleted) | [backend#50](https://github.com/0xfederama/collections-app-backend/pull/50) | 2026-10-20 | Brief: [features/F-018-type-refactor.md](features/F-018-type-refactor.md) |
| F-018 | F018-W1..W3 type refactor web (one PR, web 2.14.0, `api-v0.16.0`) | web orch. | **done** 2026-10-20: squash `3b73379`, tag `v2.14.0`; `npm run check` green (a few load-induced timeouts passed on rerun), e2e 50/50 on a fresh test stack, `npm run audit` clean (pointer bump pending, top-level orch.); extras: no skeleton under Home while Settings loads, About credits with logo tiles | `feature/f018-type-refactor` (deleted) | [web#69](https://github.com/0xfederama/collections-app-frontend-web/pull/69) | 2026-10-20 | |
| F-016 | F016-B1..B5 books type backend (one PR) | backend orch. | **done** 2026-10-19: squash `ed4ee06`, tags `api-v0.12.0` + `v2.1.0`, `make check` + `make test-backup` green, `make audit` clean | `feature/F016-books-type` (deleted) | [backend#36](https://github.com/0xfederama/collections-app-backend/pull/36) | 2026-10-19 | Tasks T1 to T4 in the brief; then `api-v0.12.0`, `v2.1.0` |
| F-016 | Follow-up: country-aware store links (backend) | backend orch. | **done** 2026-10-19: [backend#40](https://github.com/0xfederama/collections-app-backend/pull/40), tag `api-v0.12.1`; web syncs to it | `feature/country-aware-store-links` (deleted) | | 2026-10-19 | Amazon table + Bookshop UK + Google Play `gl`; others global |
| F-016 | Follow-up: Open Library covers + client abort (backend) | backend orch. | **done** 2026-10-19: [backend#41](https://github.com/0xfederama/collections-app-backend/pull/41), tag `v2.1.1` (no contract change, no new api tag) | `fix/openlibrary-covers-and-cancel` (deleted) | | 2026-10-19 | `make check` green, `make audit` clean; run the test stack from this commit to see real books fill |
| F-016 | Follow-up: book cleanup, contract change (backend) | backend orch. | **done** 2026-10-19: [backend#42](https://github.com/0xfederama/collections-app-backend/pull/42), squash `134fe5a`, tag `api-v0.13.0` (breaking), release tag `v2.2.0` (user decision: minor despite the break, avoids clashing with the accounts 3.0.0) | `feature/F016-book-cleanup` (deleted) | | 2026-10-19 | `make check`, `make test-backup`, `make audit` green; web syncs to api-v0.13.0 |
| F-016 | Follow-up: row store links + streaming link (backend) | backend orch. | **done** 2026-10-19: [backend#45](https://github.com/0xfederama/collections-app-backend/pull/45), squash `f21612a`, tag `api-v0.14.0` (additive, no migration); release tag `v2.3.0` | `feature/row-store-links-streaming-link` (deleted) | | 2026-10-19 | `make check`, `make audit` green; live check on the test stack; web syncs to api-v0.14.0, existing movies get the link on next refresh |
| F-016 | Follow-up: platform search links, link backfill, Runtime label (backend) | backend orch. | **done** 2026-10-19: [backend#46](https://github.com/0xfederama/collections-app-backend/pull/46) (migration 000024), [#47](https://github.com/0xfederama/collections-app-backend/pull/47) (backfill), [#48](https://github.com/0xfederama/collections-app-backend/pull/48) (`streaming.platform_links`, tag `api-v0.15.0`, additive); release tag `v2.4.0` | worktrees (deleted) | | 2026-10-19 | `make check` on each, `make test-backup` for 000024, `make audit` before the tag; platform URL patterns are unverified, check them in a browser |
| F-016 | **TODO** Book lookup quality: (1) backend: evaluate Google Books as a second source for non-English titles (free but needs an API key; verify current terms on storing data/covers; test the six B1 titles and "il vecchio e il mare"), (2) backend: when the first result has no author, prefer the first same-title result that has one, (3) web: handle a missing author gracefully (visible hint, easy edit, "Wrong match?" nudge) and review the other places that assume a complete lookup | top-level orch. to schedule | **done** (Google dropped, Hardcover gap-filler in backend#44; see D-102). Release `v2.2.1`. Earlier note: 2026-10-19: (2) shipped in [backend#43](https://github.com/0xfederama/collections-app-backend/pull/43) (prefers the same-title result with author and pages). Google Books evaluated and dropped: keyless quota exhausted, its terms forbid permanent copies of its data, and none of its ISBNs resolved in Open Library for Italian editions. Still open: "il vecchio e il mare" has no complete Open Library record (only the English work has one) | | | 2026-10-19 | Cause: Open Library records for many Italian titles have no author (e.g. OL34961077W); names are not localized across languages |
| F-016 | F016-W1..W4 books type web (one PR) | web orch. | **done** 2026-10-19: squash `dc5b6bd`, tags `v2.7.0`, `v2.7.1`, `v2.8.0`, `v2.8.1`, `v2.8.2`, `v2.9.0`, `v2.10.0` (web 2.10.0, `api-v0.13.0`; W2 revised to lookup on commit), `npm run check` + e2e (all but the `tree-dnd` flake, which also fails on main) + `npm audit` clean | `feature/books-type` (deleted) | [web#54](https://github.com/0xfederama/collections-app-frontend-web/pull/54) | 2026-10-19 | Pointer bump in parent pending (top-level orchestrator) |
| F-014 | F014-B1..B5 custom fields and kinds | backend orch. | done | `feature/F014-custom-fields-kinds` | [backend#31](https://github.com/0xfederama/collections-app-backend/pull/31) | 2026-10-18 | Squash-merged `4ebeb83`; `api-v0.10.0` and `v1.6.0` tagged. |
| F-014 | Kind defaults contract follow-up | backend orch. | done | `fix/kind-defaults-contract` | [backend#32](https://github.com/0xfederama/collections-app-backend/pull/32) | 2026-10-19 | Squash-merged `652d223`; `make check` and audit green; `api-v0.10.1` published. Web W2 can now sync the replacement contract. |
| F-014 | F014-W1..W4 custom fields and kinds | web orch. | done | `feature/F014-custom-fields-kinds` | [web#52](https://github.com/0xfederama/collections-app-frontend-web/pull/52) | 2026-10-19 | Squash-merged `268c6a5`; `v2.5.0` tagged; check, audit and e2e (34/34, fresh stack) green. Open: built-in kinds have no default pinned fields in the backend seed (old web default was runtime + streaming for movies); kind delete reads affected lists from the tree (no backend preview). |
| F-015 | Settings rework, kind to type, no-type lists | web orch. | done | `feature/F015-settings-and-types` | [web#53](https://github.com/0xfederama/collections-app-frontend-web/pull/53) | 2026-10-19 | Squash-merged; `v2.6.0` tagged; adopts `api-v0.11.0`; check, audit and e2e green. |
| F-015 | Backend: kind to type, no generic type, price from definition | user | done | — | [backend#34](https://github.com/0xfederama/collections-app-backend/pull/34), [#35](https://github.com/0xfederama/collections-app-backend/pull/35) | 2026-10-19 | Squash-merged `f56dec3`, `fb47d12`; tags `api-v0.11.0`, `v2.0.0`, `v2.0.1`. Brief and D-094 written afterwards. |
| F-014 | Restore default pinned fields on built-in kinds (user fix) | user | done | — | [backend#33](https://github.com/0xfederama/collections-app-backend/pull/33) | 2026-10-19 | Squash-merged `0a54774`; tag `v1.6.1`. Closes the open item from web#52. |
| F-000 | F000-B1 install v2 agents + rules | backend orch. | done | `chore/adopt-workflow-v2` | [backend#16](https://github.com/0xfederama/collections-app-backend/pull/16) | 2026-10-15 | Squash-merged `f918264`, pointer bumped. Gate green. Smoke ran as an equivalent sonnet/medium dispatch (registry didn't reload mid-session); the next backend session confirms a native `worker` dispatch |
| F-000 | F000-W1 install v2 agents + rules | web orch. | done | `chore/adopt-workflow-v2` | [web#16](https://github.com/0xfederama/collections-app-frontend-web/pull/16) | 2026-10-15 | Squash-merged `5dc2586`, pointer bumped. Gate green (1200 tests). Smoke worker ran on Sonnet 5.5. The running session picks up a new agent file after a short delay (no restart needed) |
| F-006 | 1.0.1 polish (W1–W9) | web orch. | done (web) | one per story (see brief) | web#18–#25 | 2026-10-15 | All web stories merged, plus version 1.0.1 ([web#26](https://github.com/0xfederama/collections-app-frontend-web/pull/26)); pointer → `51db3dc`. W8 CSP PASS on the prod web image + test backend (trial `./deploy/prod` refused by auto mode). Next: top-level orch. tags v1.0.1; U1 is the user's |
| F-007 | Lists & items restructure + exploration fixes (1.1.0) | top-level orch. + user | **done** 2026-10-15 (backend#18, web#28; pointers bumped; PRODUCT/DATA_MODEL updated); tagged `v1.1.0` (parent 8e32b68, web 5587dd7, backend be8a532) | | [backend#18](https://github.com/0xfederama/collections-app-backend/pull/18) | 2026-10-15 | One kind per list, trimmed fields, addable price, list description, 6 UI fixes (D-079), `api-v0.3.0` |
| F-002 | UI refresh web (W1–W5) | web orch. | **done (web)** 2026-10-15: squash-merged `893da29`; gate green, e2e 14/14 | | [web#30](https://github.com/0xfederama/collections-app-frontend-web/pull/30) | 2026-10-15 | Uses `api-v0.5.0` (backend fe58ae5, incl. F002-B5). Closed by top-level orch.: pointers bumped, D-083 recorded, UI_SPEC §11 pointer, web 2.0.0 tagged (`v2.0.0`) |
| F-003 | Brief e2e safety net | top-level orch. + user (backend orch.: F003-B1) | **done** 2026-10-15: F003-B1 and F003-W1 merged; pointers bumped | | [backend#19](https://github.com/0xfederama/collections-app-backend/pull/19), [web#29](https://github.com/0xfederama/collections-app-frontend-web/pull/29) | 2026-10-15 | `make smoke` (backend) + ~8 Playwright specs (web); lean workflow (D-081) |
| F-005 | Ops hardening: EXIF strip (backend), scheduled backup + backup-status + audit rule (parent) | top-level orch. + user | **done** 2026-10-15 (runbook step added; server steps: you); parent P1–P3 done; backend B1 **done**: squash `12bdd81`, tag `v1.2.1`, `make audit` clean; pointer bumped; to do: runbook step + run `strip-images` on the server | [backend#22](https://github.com/0xfederama/collections-app-backend/pull/22) | 2026-10-15 | Backend 1.2.1; lean workflow; no CI (D-084) |
| F-008 | UI polish after 2.0.0 (W1–W14, B1) | top-level orch. + user | **done** 2026-10-16; backend F008-B1 **done**: squash `b1b719e`, tags `api-v0.6.0` + `v1.2.2`; web W1–W14 **done**: squash `eba8459`, tag `v2.1.0`, `npm run check` + e2e green, `npm audit` clean | [web#32](https://github.com/0xfederama/collections-app-frontend-web/pull/32) | [backend#23](https://github.com/0xfederama/collections-app-backend/pull/23) | 2026-10-15 | web 2.1.0, backend 1.2.2 (`api-v0.6.0`); lean workflow |
| F-009 | UI polish 2 (B1–B2, W1–W7) | top-level orch. + user | backend **done** 2026-10-16 (squash `6374556`, tags `api-v0.7.0` + `v1.3.0`, `make check` + `make test-backup` green, `make audit` clean); web W1–W7 **merged** 2026-10-16 (squash `80a40bb`, with F-010 and F-011): `npm run check` green (1281 tests + image), e2e 21/21 on a fresh `./deploy/test`; 2.2.0 bumped (web#39, `npm run audit` clean); **pending: tag `v2.2.0`** | `feature/F009-ui-polish-2` | [web#37](https://github.com/0xfederama/collections-app-frontend-web/pull/37), [backend#24](https://github.com/0xfederama/collections-app-backend/pull/24) | 2026-10-16 | web 2.2.0, backend 1.3.0 (`api-v0.7.0`); lean workflow; price on motorcycle/car/camera only; pinned_fields ordered list ≤2 |
| F-002 | F002-B1..B4 backend contract (one PR) | backend orch. | **done** | | [backend#20](https://github.com/0xfederama/collections-app-backend/pull/20) | 2026-10-15 | Squash-merged `5b3c244`, tag `api-v0.4.0` pushed (D-082); web: `npm run api:sync -- api-v0.4.0`. B5 (metadata on `ItemSummary`, gap found by web) shipped in [backend#21](https://github.com/0xfederama/collections-app-backend/pull/21), squash `fe58ae5`, tag `api-v0.5.0`: web syncs to that |
| F-010 | F010-W1 folder path when creating a list | web orch. | **done (web)**, merged 2026-10-16, folded into [web#37](https://github.com/0xfederama/collections-app-frontend-web/pull/37) at the user's request | `feature/F009-ui-polish-2` | [web#37](https://github.com/0xfederama/collections-app-frontend-web/pull/37) | 2026-10-16 | One PR, separate commits, squashed at the end. Session-only memory (`sessionStorage`), frontend only. Brief: [features/F-010-new-list-folder.md](features/F-010-new-list-folder.md) |
| F-011 | F011-W1..W6 review fixes (streaming, hovers, folder dropdown) | web orch. | **done** 2026-10-16, merged in [web#37](https://github.com/0xfederama/collections-app-frontend-web/pull/37) | `feature/F009-ui-polish-2` | [web#37](https://github.com/0xfederama/collections-app-frontend-web/pull/37) | 2026-10-16 | Brief: [features/F-011-review-fixes.md](features/F-011-review-fixes.md). W1 no country on the item, W2 platforms as a multi-choice dropdown, W3 sidebar "…" slimmer hover, W4 field pen + label alignment, W5 "+ New" inset focus ring, W6 folder as a dropdown beside Kind. No contract change |

| F-012 | F012-W1..W4 list icons, paste, trash controls | web orch. | done | — | [web#40](https://github.com/0xfederama/collections-app-frontend-web/pull/40) | 2026-10-16 | Squash-merged `ae5fd90`, tag `v2.3.0` pushed; parent web pointer bumped. api-v0.8.0. All gate stages validated (full suite + focused corrections: 1300 tests, 1 existing skip); all 30 distinct e2e cases verified on fresh test stack, both-theme picker axe + production mobile QA; audit 0 vulnerabilities. Branches/worktrees deleted |

| F-012 | Follow-up: compact create icon and item field editors | web orch. | done | — | [web#42](https://github.com/0xfederama/collections-app-frontend-web/pull/42) | 2026-10-16 | Squash `cd62669`; Icon beside Name, simple item input and ✓/✕ in one row. All gate stages passed (1300 tests + 1 existing skip, image); 12 affected e2e cases verified on fresh test stack, 375/1440 visual checks, both-theme picker axe. Parent pointer bumped; branch deleted |

| F-013 | F013-B1..B5 TMDB lookup, director, settings; E2E TMDB fixture | backend orch. | done (backend) | — | [backend#28](https://github.com/0xfederama/collections-app-backend/pull/28) | 2026-10-17 | Squash-merged `e9abee1`; parent pointer bumped. `make check` passed and an isolated no-key Docker stack returned `[mock] movie name`. Other test-stack queries may use the configured real key for manual experiments. |
| F-013 | F013-W1..W4 TMDB lookup, director, settings | web orch. | done | — | [web#43](https://github.com/0xfederama/collections-app-frontend-web/pull/43) | 2026-10-17 | Squash-merged `82dfe26` and tagged `v2.4.0`; `api-v0.9.0` pinned. All development workers used Simple / GPT 6 Luna (medium); `npm run check`, a fresh-stack 33-test E2E run, and `npm run audit` passed. Parent pointer bumped; branch deleted. |
| F-013 | Web follow-up: recover from unavailable TMDB lookup on create | web orch. | done | — | [web#45](https://github.com/0xfederama/collections-app-frontend-web/pull/45) | 2026-10-17 | Squash-merged `28a7789`; typed titles are retained and users can retry metadata lookup or create without it after `503 upstream_unavailable` / `lookup_disabled`. `npm run check` and 33-test E2E passed; parent pointer bumped and branch deleted. |
| F-013 | Web follow-up: settings grouping and populated item fields | web orch. | done | — | [web#46](https://github.com/0xfederama/collections-app-frontend-web/pull/46) | 2026-10-17 | Squash-merged `4b6f31e`; Appearance → Collection → Movies & TV Settings grouping, no item-level TMDB controls, and every populated item field shown by default. `npm run check` and fresh-stack 33-test E2E passed; parent pointer bumped and branch deleted. |
| F-013 | Web follow-up: separate Collection and Movies & TV section cards | web orch. | done | — | [web#47](https://github.com/0xfederama/collections-app-frontend-web/pull/47) | 2026-10-17 | Squash-merged `d8c0a1d`; Collection and Movies & TV now use separate section cards; Details precedes left-aligned saved streaming services. `npm run check` and fresh-stack 33-test E2E passed; parent pointer bumped and branch deleted. |
| F-013 | Web follow-up: save settings when the pane closes | web orch. | done | — | [web#48](https://github.com/0xfederama/collections-app-frontend-web/pull/48) | 2026-10-17 | Squash-merged `ce05e84`; ordinary settings save on pane close, while validation, conflict, and network recovery keep the pane open. `npm run check` and fresh-stack 33-test E2E passed; parent pointer bumped and branch deleted. |
| F-013 | Web follow-up: commit selected TMDB suggestion on selection | web orch. | done | — | [web#49](https://github.com/0xfederama/collections-app-frontend-web/pull/49) | 2026-10-18 | Squash-merged `d21adf8`; pointer and keyboard TMDB suggestion selection now create the selected movie/TV item immediately, while typed-title submission and lookup recovery remain intact. `npm run check` and fresh-stack 33-test E2E passed; branch deleted. |
| F-013 | Web follow-up: make the Quick add list picker readable | web orch. | done | — | [web#50](https://github.com/0xfederama/collections-app-frontend-web/pull/50) | 2026-10-18 | Squash-merged `6533000`; the wider Quick add list picker keeps selected labels on one line and truncates true overflows. `npm run check` and fresh-stack 33-test E2E passed; branch deleted. |
| F-013 | Web follow-up: contain sidebar and content scrolling | web orch. | done | — | [web#51](https://github.com/0xfederama/collections-app-frontend-web/pull/51) | 2026-10-18 | Squash-merged `0f249e7`; the persistent sidebar is viewport-bounded so its tree scrolls independently while `main` remains the content scroll owner. `npm run check` passed (1,317 tests; 1 skipped); branch deleted. |
| F-013 | Backend follow-up: correct TMDB paid-provider mapping and Italian metadata default | backend orch. | done | — | [backend#30](https://github.com/0xfederama/collections-app-backend/pull/30) | 2026-10-17 | Squash-merged `19e7025`; parent pointer bumped. `flatrate` is subscription availability, not a per-title payment; rent/buy-only providers are paid. New workspaces default TMDB metadata to `it-IT`. `make check` passed. |

## 1.0 release checks (done, v1 workflow)

| Task | Owner | State | Branch | PR | Updated | Notes |
|---|---|---|---|---|---|---|
| Q-04 fresh clone (AT-01) | v1 backend orch. | done | `docs/Q-04-readme-fixes` | [backend#14](https://github.com/0xfederama/collections-app-backend/pull/14) | 2026-10-15 | Test + prod modes and both gates OK. Parent doc fixes `cb6e5b7`, backend README `2fc516f`. Web README gaps + flaky ItemEditForm test → web orchestrator (handoffs/Q-04.md Questions) |
| Q-05 scope fence (AT-19) + security review | v1 backend orch. → reviewer session | done | `fix/Q-05-review` | [backend#15](https://github.com/0xfederama/collections-app-backend/pull/15) | 2026-10-15 | Scope fence clean, no critical/high. govulncheck fixes squash-merged as `ea0b1c5`; findings table in handoffs/Q-05.md. Web follow-up: IMDb link scheme check (low). Live CSP check → C4 smoke |
| C4 smoke checklist (D-068) | v1 web orch. + user | done | | | 2026-10-15 | Items 1–13 PASS on `./deploy/test --fresh`; 14 (backup/restore) covered by AT-17 + the Q-03 prod run. Non-blocking findings → F-006 |
| Backup → wipe → restore on dev | user | carried over | — | — | 2026-10-15 | → F-006 U1 (or F-005) |
| Tag `v1.0.0`, roadmap update, start v2 | top-level orch. | done | — | — | 2026-10-15 | Tags pushed in backend, web, parent |

## v1 record: M0–M5 tasks

M1/M2 web rows (added by the web orchestrator):

| Task | Repo | State | Branch | PR | Updated | Notes / blockers |
|---|---|---|---|---|---|---|
| W-03 | web | done | `feature/W-03-design-system` | [#2](https://github.com/0xfederama/collections-app-frontend-web/pull/2) | 2026-10-14 | Squash-merged as `320208c`; `npm run check` re-run green on main. Branch and worktrees removed |
| W-02 | web | done | `feature/W-02-api-client` | [#3](https://github.com/0xfederama/collections-app-frontend-web/pull/3) | 2026-10-14 | Squash-merged as `39d81ff` (D-058). Branch and worktree removed. `VITE_API_MOCKS=1` dev not yet tried in a real browser |
| W-04 | web | done | `feature/W-04-app-shell` | [#4](https://github.com/0xfederama/collections-app-frontend-web/pull/4) | 2026-10-14 | Squash-merged as `8b6110a`. Branch and worktree removed. Breadcrumbs owned by the shell (UI_SPEC §3 amended) |
| W-05 | web | done | `feature/W-05-tree-actions` | [#5](https://github.com/0xfederama/collections-app-frontend-web/pull/5) | 2026-10-14 | Squash-merged as `c812c9d`. Branch and worktree removed. Open: VoiceOver pass on "Picked up…" announcement; no right-click/Shift+F10 menu (More button instead) |
| W-06 | web | done | `feature/W-06-list-view` | [#6](https://github.com/0xfederama/collections-app-frontend-web/pull/6) | 2026-10-14 | Rebased on W-05, squash-merged as `89e045c` (D-063). Branch and worktree removed. Follow-ups (panel close keeps query, lazy routes) moved to W-07 |
| W-07 | web | done | `feature/W-07-item-detail` | [#8](https://github.com/0xfederama/collections-app-frontend-web/pull/8) | 2026-10-14 | Squash-merged as `d64e6b6`. Lazy routes (entry 675→564 kB), panel close keeps query. Branch and worktree removed. Next: W-08 |
| W-11 | web | done | `feature/W-11-search` | [#7](https://github.com/0xfederama/collections-app-frontend-web/pull/7) | 2026-10-14 | Rebased on W-07, squash-merged as `f65d620`; real-backend search checked. Branch and worktree removed |
| W-08 | web | done | `feature/W-08-item-edit` | [#10](https://github.com/0xfederama/collections-app-frontend-web/pull/10) | 2026-10-14 | Squash-merged as `8b9d014` on top of W-12; `npm run check` green on main (979 tests). Branch and worktree removed |
| W-12 | web | done | `feature/W-12-trash` | [#9](https://github.com/0xfederama/collections-app-frontend-web/pull/9) | 2026-10-14 | Squash-merged as `d9d2ccb`. Branch and worktree removed |
| W-09 | web | done | `feature/W-09-item-image` | [#11](https://github.com/0xfederama/collections-app-frontend-web/pull/11) | 2026-10-14 | Squash-merged as `162faab`. Branch and worktree removed. Not checked: 40 MP case in the UI, live progress on a slow link |
| W-10 | web | done | `feature/W-10-content-editor` | [#13](https://github.com/0xfederama/collections-app-frontend-web/pull/13) | 2026-10-15 | Squash-merged as `c8d1ba0`. Branch and worktree removed |
| W-13 | web | done | `feature/W-13-settings-home` | [#14](https://github.com/0xfederama/collections-app-frontend-web/pull/14) | 2026-10-15 | Squash-merged on top of W-10. Client synced to `api-v0.2.0` (recent items, D-070). Branch and worktree removed |
| T-01 | web | done | `chore/T-01-test-stability` | [#15](https://github.com/0xfederama/collections-app-frontend-web/pull/15) | 2026-10-15 | Squash-merged as `2b9e7a6`; `npm run check` green on main (1200 tests + image build). Branch and worktree removed |
| Q-01a | web | deferred | — | — | 2026-10-14 | Post-MVP (D-068). C4 uses the smoke checklist in ACCEPTANCE_TESTS.md |
| Q-01b | web | deferred | — | — | 2026-10-14 | Post-MVP (D-068) |
| Q-03w | web | done | `feature/Q-03w-web-image` | [#12](https://github.com/0xfederama/collections-app-frontend-web/pull/12) | 2026-10-15 | Squash-merged as `f1df021` (D-072). Orchestrator spot-checked CSP/headers/Dockerfile. `npm run check` now builds the image (needs Docker). Branch and worktree removed. Unblocks Q-03 |

M1 backend rows (added by the backend orchestrator):

| Task | Repo | State | Branch | PR | Updated | Notes / blockers |
|---|---|---|---|---|---|---|
| B-02 | backend | done | `feature/B-02-schema-sqlc` | [#2](https://github.com/0xfederama/collections-app-backend/pull/2) | 2026-10-14 | Squash-merged as `70cb527` (tree identical to the reviewed head); C1 schema approved by the user. Branch and worktree removed |
| B-03 | backend | done | `feature/B-03-openapi` | [#3](https://github.com/0xfederama/collections-app-backend/pull/3) | 2026-10-14 | Squash-merged as `ae8ae4e`; C1 spec approved (D-054, create with missing parent → 409). Branch and worktree removed. Tag `api-v0.1.0` pushed |
| B-04 | backend | done | `feature/B-04-foundations` | [#4](https://github.com/0xfederama/collections-app-backend/pull/4) | 2026-10-14 | Squash-merged as `d48ecc1` (D-055–D-057). Branch and worktree removed |
| B-05 | backend | done | `feature/B-05-workspace-settings` | [#5](https://github.com/0xfederama/collections-app-backend/pull/5) | 2026-10-14 | Squash-merged as `67e5f17` (D-059). Branch and worktree removed |
| B-06 | backend | done | `feature/B-06-folders-lists` | [#6](https://github.com/0xfederama/collections-app-backend/pull/6) | 2026-10-14 | Rebased on B-05, squash-merged as `a3bc87a` (D-060). Branch and worktree removed |
| B-07 | backend | done | `feature/B-07-items` | [#7](https://github.com/0xfederama/collections-app-backend/pull/7) | 2026-10-14 | Squash-merged as `371e0c1` (D-062). Branch and worktree removed |
| B-08 | backend | done | `feature/B-08-content` | [#8](https://github.com/0xfederama/collections-app-backend/pull/8) | 2026-10-14 | Squash-merged as `4c73f85`. Branch and worktree removed |
| B-09 | backend | done | `feature/B-09-images` | [#10](https://github.com/0xfederama/collections-app-backend/pull/10) | 2026-10-14 | Rebased on B-08 + B-11, squash-merged as `9c583e3` (D-064; EXIF strip of originals is a future to-do, DATA_MODEL §9). Branch and worktree removed |
| B-10 | backend | done | `feature/B-10-trash` | [#11](https://github.com/0xfederama/collections-app-backend/pull/11) | 2026-10-14 | Squash-merged as `35d5deb`. All API operations implemented; no spec change since `api-v0.1.0` (B-12 not needed). Branch and worktree removed |
| Q-02 | backend | done | `feature/Q-02-backup-restore` | [#12](https://github.com/0xfederama/collections-app-backend/pull/12) | 2026-10-14 | Squash-merged as `d680a9a` (D-066). `make test-backup` green. Open: manual backup → reset-dev → restore on the dev stack (user). Branch and worktree removed |
| B-12 | backend | done | `feature/B-12-recent-items` | [#13](https://github.com/0xfederama/collections-app-backend/pull/13) | 2026-10-14 | Squash-merged as `98d3b87` (D-070). Tag `api-v0.2.0` pushed (user OK). Branch and worktree removed |
| Q-03 | parent + backend | done | — (parent, no backend PR) | — | 2026-10-15 | Parent `deploy/server/` (compose, check.sh), `./deploy/prod` wrapper, README, D-071. Final run with the real web image passed (deep link, CSP 0 violations, upload, backup→wipe→restore→verify, exposure); details in handoffs/Q-03.md |
| Q-04 | parent + backend | done | `docs/Q-04-readme-fixes` (backend) | [backend#14](https://github.com/0xfederama/collections-app-backend/pull/14) | 2026-10-15 | Moved to F001-B1 (D-074); squash-merged as `2fc516f` |
| B-11 | backend | done | `feature/B-11-search` | [#9](https://github.com/0xfederama/collections-app-backend/pull/9) | 2026-10-14 | Rebased on B-08, squash-merged as `08d30ab`. Branch and worktree removed |

M0 record:

| Task | Repo | State | Branch | PR | Updated | Notes / blockers |
|---|---|---|---|---|---|---|
| M0-U | — | done | — | — | 2026-10-13 | Repos created and cloned. License still open (Q-4) |
| R-1 | both | done | — | — | 2026-10-13 | Versions + D-035–D-042 in DECISIONS.md |
| R-2 | backend | done | — | — | 2026-10-13 | OpenAPI 3.0.3, oapi-codegen, Redocly (D-041) |
| B-00 | backend | done | `chore/B-00-skeleton` | [#1](https://github.com/0xfederama/collections-app-backend/pull/1) | 2026-10-14 | Squashed and rebase-merged as `d867326`. `make check` + compose verified |
| B-01 | backend | dropped | — | — | 2026-10-13 | No CI for now (D-031); local `make check` from B-00 |
| W-00 | web | done | `chore/W-00-skeleton` | [#1](https://github.com/0xfederama/collections-app-frontend-web/pull/1) | 2026-10-14 | Squashed and rebase-merged as `835a040`. `npm run check` + dev proxy verified |
| W-01 | web | dropped | — | — | 2026-10-13 | No CI for now (D-031); local `npm run check` from W-00 |

## Notes for repo orchestrators (from M0, 2026-10-14)

**Start order** (backend#1 and web#1 merged 2026-10-14; parent pointers bumped to the merged `main` commits):
backend B-02 → (user review) → B-03 → tag `api-v0.1.0` (ask the user before pushing the tag) → web W-02. Web W-03 only
needs W-00, so it runs in parallel with backend M1 (needs Q-6 answered or the default accepted). Then M2 per the plan.

**Backend (`make check` today: gofmt check, golangci-lint with goimports + noctx, `go test ./...` on testcontainers
Postgres, AT-18 compose exposure, `docker build`).**
- Tools: add `sqlc` and `oapi-codegen` with `go get -tool …@<version>` and run them as `go tool …` (D-035). golangci-lint stays
  `go run …@v2.14.0`. Redocly runs pinned via `npx` or its Docker image (D-041). Wire both generators into `make generate`.
- B-02 must add to `check`: `sqlc generate` + `git diff --exit-code` drift check, and a migrations up → down → up test on a
  fresh testcontainers Postgres. Once `000001` exists the compose migrate guard (D-037) is a no-op; keep it.
- B-03 must add to `check`: Redocly lint of `api/openapi.yaml` and an oapi-codegen drift check. Generated code goes under
  `internal/` (the Dockerfile copies only `cmd/` and `internal/`; `make check-docker` fails otherwise).
- `http.Server` has `ReadTimeout` 30s / `WriteTimeout` 60s globally. B-04/B-09 should set per-route body limits and
  revisit timeouts for 10 MB uploads.
- Not covered by tests yet: `cmd/api` (wiring, `healthcheck` subcommand, verified manually) and `internal/database`
  (B-04's `InTx` tests should cover `NewPool`). `APP_ENV` only gates `make reset-dev` today.
- Logs: slog JSON by default. Request IDs, access log, recovery and security headers are B-04.

**Web (`npm run check` today: Prettier incl. Markdown, ESLint, `tsc`, Vitest on jsdom, `vite build`).**
- Lean rule (D-034): each task installs only what it uses. W-02 adds openapi-typescript, openapi-fetch, TanStack Query, MSW,
  `api:sync` / `api:check` (joins `check`), and replaces `src/lib/backendStatus.ts` with `lib/api`. Decide then whether the
  `/healthz` and `/readyz` dev proxies are still needed.
- W-03 adds Radix per-primitive (D-038), Fontsource, tokens for light and dark, the no-flash theme bootstrap, `color-scheme`
  (deliberately removed in M0) and a favicon.
- TypeScript stays on 6.x until typescript-eslint supports 7 (D-040). React Router 8: import from `react-router`.

**Both / parent.**
- The parent local stack (`deploy/local/compose.yaml`, web on `127.0.0.1:5173`) is not covered by the AT-18 script, which only renders the backend
  compose. Prod has its own exposure check (`./deploy/prod check`).
- GitGuardian scans every push: no `user:pass@host` strings, blank secrets in examples (see backend CLAUDE.md gotchas).
- Parent commits go straight to `main` by pathspec (D-044). Service repos are PR-only; the user merges.

## Repos

| Repo | Remote | Local path | Latest API tag |
|---|---|---|---|
| backend | https://github.com/0xfederama/collections-app-backend | `/Users/federico/Developer/collections-app/backend` (submodule) | `api-v0.7.0` (`6374556`) |
| web | https://github.com/0xfederama/collections-app-frontend-web | `/Users/federico/Developer/collections-app/frontend-web` (submodule) | pinned: — |
| parent | https://github.com/0xfederama/collections-app | `/Users/federico/Developer/collections-app` | — |

## Waiting on the user

- Q-4 license (DECISIONS.md). Default applies if unanswered.

## Log (newest first, one line each)

- 2026-10-16: **F-011** (review fixes requested on [web#37](https://github.com/0xfederama/collections-app-frontend-web/pull/37), 2026-10-16): F011-W1 the item's streaming editor no longer asks for a country (Settings only — the contract still requires `metadata.streaming.country`, so the draft keeps sending the item's own or the Settings one, no contract change). F011-W2 the platforms are a multi-choice dropdown over the services we ship logos for, plus a field for one we don't. F011-W3 the tree row's "…" paints no hover fill of its own (it drew a second box as big as the row; option A chosen from an HTML mockup). F011-W4 the field pen shares the row's background and its name lines up with its value. F011-W5 "+ New" uses the repo's inset focus ring (the outer one was clipped by the scroll container). F011-W6 the new-list folder is a dropdown **beside** Kind, labelled with the full path. `npm run check` green (1281 tests + image) and e2e **21/21** on a fresh `./deploy/test`. **Gotcha for the next e2e run:** the drag specs fail on the *first* run after `./deploy/test up -d --fresh` — the Vite dev server compiles on the first request and the drag times out; they pass on a warm run (bisected commit by commit before concluding).
- 2026-10-16: **F-010-W1 folded into web#37** at the user's request (one PR, separate commits, squashed at the end); #38 closed and its branch deleted. The "New list" dialog picks the folder, defaulting to the opener's folder, else the folder the last created list went into, else Top level, remembered in **`sessionStorage`** (`collection:list-folder`), written only after a successful create, so it ends with the tab like a cookie. Frontend only (`folder_id` was already on `POST /lists`).

- 2026-10-16: **F-010-W1** (requested while reviewing F-009 web, 2026-10-16): the "New list" dialog gets a folder picker (the shared `DestinationPicker`, Top level first), defaulting to the opener's folder, else the folder the last created list went into, else Top level. Remembered in **`sessionStorage`** (`collection:list-folder`), written only after a successful create, so it ends with the tab like a cookie and never leaves the browser. Frontend only (`folder_id` was already on `POST /lists`); lists only, not folders. Split into its own PR rather than folded into #37 (one concern per PR; the two share no files): [web#38](https://github.com/0xfederama/collections-app-frontend-web/pull/38). Branched from `main`, so it needs a rebase once #37 merges (clean: no shared files). Gate green; e2e 18/19 on this branch alone (`main`'s movie-price spec is stale, #37 fixes it) and **20/20** cherry-picked onto #37. Needs a brief from the top-level orchestrator; recorded here meanwhile.

- 2026-10-16: F-009 **web W1–W7** implemented on `feature/F009-ui-polish-2` (one PR, D-079/D-081 lean): contract synced to `api-v0.7.0`, ordered pinned fields (≤2), kind-matched sort and pins, calm item page, streaming row, Move/Delete at the bottom, one icon tile, centred empty Trash. `npm run check` green (1274 tests + prod image) and `npm run e2e` 19/19 on a fresh `./deploy/test`. Orchestrator decisions: `tv_show` default pins streaming, "+ Add field" reveals a set field read-only, `firstLetter` moved to `lib/text.ts`. Next: review, merge, version 2.2.0 + `npm run audit` + tag `v2.2.0`.

- 2026-10-16: F-009 backend (F009-B1+B2) **done**: [backend#24](https://github.com/0xfederama/collections-app-backend/pull/24) squash-merged `6374556`; tags `api-v0.7.0` and `v1.3.0` pushed; `make check` + `make test-backup` (AT-17) green; `make audit` (govulncheck) clean; parent pointer bumped. Price only on motorcycle/car/camera; `pinned_fields` is an ordered array ≤2 (D-085). Next: web F009-W1–W7 (W2/W3 pin to `api-v0.7.0`).

- 2026-10-15: **v1.0.0 released**: tags in backend (`ea0b1c5`), web (`2b9e7a6`) and parent. **Workflow v2 starts**: v1 orchestrators dismissed; F-000 (install v2 agents) approved; F-006 (1.0.1 polish) drafted for the user's OK.

- 2026-10-15: C4 smoke checklist (web, D-068) run in the browser pane against `./deploy/test --fresh` on web main 2b9e7a6 / backend api-v0.2.0: items 1–13 PASS, 14 (backup/restore) left to the backend prod drill. Non-blocking findings for a web polish task: Home "Recently updated" stale after deleting a folder (needs reload); sidebar tree may not be reachable by Tab alone (to confirm); focus not returned after Esc on Add item; delete-confirm vs Trash counts wording differ (root folder counted only in Trash).
- 2026-10-15: Q-05 done: backend#15 (govulncheck dependency bumps) squash-merged (`ea0b1c5`), parent pointer bumped. Scope fence clean, no critical/high findings. Remaining for 1.0: C4 smoke checklist (incl. live CSP check), dev restore drill, then `v1.0.0` tags.

- 2026-10-15: Brief handoffs/Q-05.md written (reviewer session, both repos). Runs in parallel with the C4 smoke checklist.

- 2026-10-15: **v2 switch postponed** (user): the v1 orchestrators finish Q-05 and C4 first; v2 (D-074) starts after. The F-001 brief is a summary only. ROADMAP F-002 (UI refresh) kept generic: a large, mostly aesthetic refactor, designed by the user later (D-075).

- 2026-10-15: F001-B1 (was Q-04) done: backend#14 squash-merged (`2fc516f`), parent pointer bumped. Open for the web orchestrator: web README is still the M0 skeleton, flaky ItemEditForm test (handoffs/Q-04.md Questions). Next backend: F001-B0 + F001-B2 by a v2 backend orchestrator.

- 2026-10-15: **Workflow v2** (D-074): top-level orchestrator + repo orchestrators (Opus 5.5 medium) + internal `worker` agents (Sonnet 5.5 medium, flag-only review). v1 orchestrators dismissed. `ROADMAP.md` created (1.0 → F-001 to F-005, 2.0 TMDB, 3.0 accounts). Q-04/Q-05 folded into F-001.

- 2026-10-15: T-01 squash-merged (web `main` 2b9e7a6), full gate green on main incl. image build. **Web MVP feature-complete.** Next: C4 manual smoke checklist (D-068).
- 2026-10-15: W-13 squash-merged, parent pointer bumped; web contract now `api-v0.2.0`. Only T-01 left in the web batch, then C4 (manual smoke checklist).
- 2026-10-15: Q-03 final run with the real web image passed (backend orchestrator closed it). Brief Q-04 (fresh clone, AT-01) written; starts after W-13 and T-01 merge. Then Q-05, then the user's smoke checklist (C4).

- 2026-10-15: W-10 squash-merged (web `main` c8d1ba0), parent pointer bumped. T-01 rebases clean; W-13 conflicts only in docs/modules/items.md.
- 2026-10-15: Q-03w squash-merged (web `main` f1df021), parent pointer bumped. Q-03 (backend orchestrator) can do its final prod-compose run. `npm run check` needs Docker from now on.
- 2026-10-14: Parent: environments moved into `deploy/` (D-073): `./deploy/dev`, `./deploy/test [--fresh]`, `./deploy/prod`; `deploy/local/` and `deploy/server/` hold the compose and env files. `./app`, `env/`, root `compose.yaml` and `.env.example` removed; `deploy/.env` is now `deploy/server/.env`.

- 2026-10-14: W-09 squash-merged (web `main` 162faab), parent pointer bumped. W-10, W-13, T-01, Q-03w rebase on it.
- 2026-10-14: W-09 PR opened (web#11): item image dropzone/picker/URL/remove with XHR progress, base-version snapshot in the edit form, dev fake. Real-backend acceptance done; waiting for the user's review.
- 2026-10-14: Q-03 closed by the backend orchestrator (parent-only, `4c41afc`, D-071). Next backend-side: Q-04 (fresh clone + prod run with the real web image) after Q-03w, W-09, W-10, W-13 merge; then Q-05.

- 2026-10-14: B-12 squash-merged (backend `main` 98d3b87), tag `api-v0.2.0` pushed (user OK): `GET /recent-items` available, W-13 can sync the client. Parent pointer bumped.

- 2026-10-14: B-12 PR opened (backend#13): `GET /recent-items`, spec 0.2.0, `TestB12_*`, EXPLAIN ~4 ms at 20k items (no index). Check green; waiting for the user's review, then tag `api-v0.2.0` (user OK).

- 2026-10-14: Web orchestrator: brief handoffs/Q-03w.md written (D-069); W-13 brief updated for D-070. Current web batch: W-09, W-10, W-13, T-01, Q-03w (Q-01a dropped, D-068).
- 2026-10-14: User decisions: e2e (Q-01a/b) deferred post-MVP, C4 uses the smoke checklist (D-068); prod images built on the server, prod compose in parent `deploy/`, web image = Q-03w (D-069); W-13 gap closed by `GET /recent-items` (D-070, B-12 → `api-v0.2.0`). Briefs B-12, Q-03 written; they run in parallel.

- 2026-10-14: W-12 and W-08 squash-merged (web `main` 8b9d014), gate green on main, parent pointer bumped. Briefs W-09, W-10, W-13, Q-01 (Q-01a), T-01 written; all five can run in parallel. Contract gap: no endpoint for Home's "recently updated items (12)" (UI_SPEC §1); backend task requested.
- 2026-10-14: W-08 PR opened (web#10): item create + edit form, `?edit=1`, 412/422/network UX, unsaved guard (useBlocker + beforeunload), dev fakes for POST/PATCH. `npm run check` green (916 tests); acceptance run by hand on the real backend. Waiting for the user's review.

- 2026-10-14: Parent: `./app` launcher with prod (default) and test environments, `--test --fresh` wipes test data (D-067). `compose.fresh.yaml` removed.

- 2026-10-14: Web orchestrator: backend reported feature-complete (main d680a9a, spec still api-v0.1.0). Q-01 split: Q-01a after W-08 + W-12 (everything but AT-06), Q-01b after W-09 + W-13. API gaps found by e2e go to the backend orchestrator.
- 2026-10-14: Q-02 squash-merged (backend `main` d680a9a), parent pointer bumped. Backend idle by choice until Q-01 (needs W-12); then Q-03 → Q-04 → Q-05.

- 2026-10-14: W-11 squash-merged (web `main` f65d620), parent pointer bumped. Briefs W-08 and W-12 written (parallel).
- 2026-10-14: W-11 (web#7) rebased on W-07, force-pushed with lease; real-backend check done. Ready for review.
- 2026-10-14: Q-02 PR opened (backend#12): backup/restore/verify scripts, AT-17 `make test-backup`, shellcheck in `make check` (D-066). Waiting for the user's review.
- 2026-10-14: W-07 squash-merged (web `main` d64e6b6), parent pointer bumped. W-11 rebases on it (conflicts in docs, mocks/browser.ts, mocks/devItems.ts). Next: W-08.
- 2026-10-14: W-07 PR opened (web#8): item detail view, AT-13 links, per-kind configs, MarkdownView (react-markdown + remark-gfm), move/delete, lazy routes (entry 675 → 564 kB), panel close keeps query. Check green; waiting for the user's review.
- 2026-10-14: W-11 PR opened (web#7): sidebar search dropdown (ARIA combobox), `/search` results page, dev fake. Check green x4; browser-checked on the real backend.
- 2026-10-14: B-10 squash-merged (backend `main` 35d5deb), parent pointer bumped. **Backend M2–M3 complete**: every API operation implemented, spec unchanged since `api-v0.1.0` (B-12 not needed). Brief Q-02 (backup/restore) written; Q-01 waits for W-12.

- 2026-10-14: B-10 PR opened (backend#11): trash delete/list/restore/purge, AT-11 tests, 501 stubs removed (D-065). Check green; waiting for the user's review.
- 2026-10-14: B-09 squash-merged (backend `main` 9c583e3), parent pointer bumped. Brief B-10 (trash) written. No spec change since `api-v0.1.0`, so B-12 is not needed so far.

- 2026-10-14: W-06 squash-merged (web `main` 89e045c), parent pointer bumped. M2 web done. Briefs W-07 and W-11 written (parallel). Not yet checked for W-06: exact 768/1024/1280 widths in both themes, real-backend run.
- 2026-10-14: B-11 squash-merged (backend `main` 08d30ab), parent pointer bumped. B-09 (#10) must rebase on it; then B-10.

- 2026-10-14: B-09 PR opened (backend#10): FileStore, image upload/url/delete, file serving, orphan sweeper, own EXIF orientation (D-064). Check green; waiting for the user's review.
- 2026-10-14: W-06 (web#6) rebased on W-05, ListActionsMenu wired, shared sortable wrapper, dev mocks share one list record. Check green; waiting for the user's review.
- 2026-10-14: B-08 squash-merged (backend `main` 4c73f85), parent pointer bumped. B-11 (#9) and B-09 must rebase on it before merging.

- 2026-10-14: B-11 PR opened (backend#9): search endpoint with paths, AT-12 tests, EXPLAIN notes. Check green; waiting for the user's review.
- 2026-10-14: B-08 PR opened (backend#8): content get/save/versions/restore/retention. Check green; waiting for the user's review.
- 2026-10-14: W-05 squash-merged (web `main` c812c9d), parent pointer bumped. W-06 rebases on it and wires `ListActionsMenu`.
- 2026-10-14: W-06 PR opened (web#6): list view (3 modes, sort/filter URL state D-063, dnd-kit reorder, fallback tiles, scroll restore). Check green; waiting for the user's review.
- 2026-10-14: W-05 PR opened (web#5): folder/list CRUD dialogs, move picker, drag reorder (dnd-kit 0.5.0), stateful dev mocks. Check green; waiting for the user's review.
- 2026-10-14: B-07 squash-merged (backend `main` 371e0c1), parent pointer bumped. Briefs B-08, B-09, B-11 written; they run in parallel (later mergers rebase). B-10 waits for B-08 + B-09.

- 2026-10-14: B-07 PR opened (backend#7): items CRUD, 6 kind validators, list/sort/filter, move, reorder. Check green; waiting for the user's review.
- 2026-10-14: W-04 squash-merged (web `main` 8b6110a), parent pointer bumped. D-061 (dnd-kit: `@dnd-kit/react`, user choice). UI_SPEC §3: the shell owns breadcrumbs. Briefs W-05 and W-06 written; they run in parallel.
- 2026-10-14: B-06 squash-merged (backend `main` a3bc87a), parent pointer bumped. Brief B-07 (items) written.

- 2026-10-14: W-04 PR opened (web#4): responsive shell, sidebar tree, breadcrumbs, route skeleton, W-05/W-06 seams. Check green; waiting for the user's review.
- 2026-10-14: B-05 squash-merged (backend `main` 67e5f17), parent pointer bumped. B-06 (#6) must rebase on the new main (conflicts in the shared seam).

- 2026-10-14: B-04 squash-merged (backend `main` d48ecc1), parent pointer bumped. Briefs B-05 and B-06 written; they run in parallel (shared seam `Deps.WorkspaceID`, second to merge rebases).

- 2026-10-14: Web orchestrator: brief handoffs/W-04.md written; UI_SPEC §2 now states the tree order (folders, then lists).
- 2026-10-14: W-02 squash-merged (web `main` 39d81ff), parent pointer bumped. Next web: W-04.
- 2026-10-14: W-02 PR opened (web#3): vendored `api-v0.1.0`, `api:sync`/`api:check`, `lib/api`, TanStack Query, MSW. Check green; waiting for the user's review.
- 2026-10-14: Web orchestrator: brief handoffs/W-02.md written; worker prompt handed to the user. Process change: no full orchestrator reviews from now on (user checks PRs; orchestrator merges).
- 2026-10-14: Tag `api-v0.1.0` pushed on backend `ae8ae4e` (user OK). **W-02 is unblocked.**

- 2026-10-14: B-03 squash-merged (backend `main` ae8ae4e), parent pointer bumped. C1 reached for the backend. Next: tag `api-v0.1.0` (user OK), then W-02 and B-04 in parallel.

- 2026-10-14: B-02 squash-merged (backend `main` 70cb527), parent pointer bumped, C1 schema approved. Brief handoffs/B-03.md written.

- 2026-10-14: W-03 squash-merged (web `main` 320208c), gate green on main, parent pointer bumped. Web is idle until `api-v0.1.0`: W-02 → W-04 → (W-05 ∥ W-06).
- 2026-10-14: W-03 PR opened (web#2): tokens, themes, fonts, 18 primitives, /dev/ui. Check green; waiting for the user's review.
- 2026-10-14: Backend orchestrator: baseline `make check` green on `d867326`. D-049 (sqlc types), D-050 (migration test), D-051 (`trash_batch_id` FK with no ON DELETE action; DATA_MODEL §2/§4 updated). Brief handoffs/B-02.md written; B-03 waits for B-02 merge + C1.
- 2026-10-14: Web orchestrator: baseline `npm run check` green on `835a040`. Q-6 answered (D-046), icons D-047, W-03 scope D-048. Brief handoffs/W-03.md written; W-02 waits for `api-v0.1.0` and for W-03 to merge.

- 2026-10-14: **C0 reached.** backend#1 and web#1 squashed to one commit each (trees identical to the reviewed heads, gates re-run green) and rebase-merged: backend `main` d867326, web `main` 835a040. Branches deleted. Parent pointers bumped. Older parent commits (806dbaf, adb7e36) point at pre-squash commits that no longer exist on any branch; only check out the parent from a later commit. Next: repo orchestrators (backend B-02, web W-03).
- 2026-10-14: M0 review of both PRs. Fixed on the branches: backend `make check` adds a Docker build, goimports and noctx, pinned Go build image; web ESLint `defineConfig`, `color-scheme` removed until W-03; CLAUDE.md files say docs are versioned in the parent. Docs: AGENT_WORKFLOW §3/§7 updated for parent commits (D-044), D-045, plan deps B-01→B-00, M1 serialized (B-03 after B-02). Orchestrator notes added below.
- 2026-10-14: Parent repo `0xfederama/collections-app` created (D-043): backend/ and frontend-web/ are submodules pinned to the open skeleton PR branches (backend#1, web#1 still unmerged). Docs now versioned in the parent. After each service PR merges, bump the pointer to the merged `main` commit.

- 2026-10-13: GitGuardian flagged backend#1 (password-shaped strings in `.env.example`, `compose.yaml`, Makefile, tests). Fixed by blank secret values in examples, credentials as `?user=&password=` query params, and plain `${POSTGRES_PASSWORD}` in compose; branch amended + force-with-lease (history clean), check now passes. The earlier incident may still be open in the GitGuardian dashboard (user can resolve it).

- 2026-10-13: M0 session: R-1/R-2 done (3 sonnet researchers). User chose Radix per-primitive and TS 6.0.3. `migrate up` on an empty dir exits 1 (verified), so compose uses a guard (D-037). Starting B-00.
- 2026-10-13: B-00 and W-00 PRs opened (backend#1, web#1), both local checks green. Waiting for the user's review; not merged.

- 2026-10-13: M0 replanned: local-only gates, no GitHub CI or Dependabot, PRs only for user code review, backend in one compose, web via Vite with an `/api` proxy, lean frontend (D-031–D-034). B-01/W-01 dropped. Brief: handoffs/M0.md.

- 2026-10-13: Workflow set: one setup session (M0, both repos), then a repo orchestrator per repo that writes `handoffs/<ID>.md` briefs, then worker sessions (one task, one worktree, one PR) — AGENT_WORKFLOW §1b.

- 2026-10-13: Design package v1 written. Kinds, dark theme, repo names, and the unversioned-docs policy were decided (D-026–D-030).
- 2026-10-16: web#37 (F-009 W1–W7 + F-010-W1 + F-011) reviewed by the top-level orch. (report + targeted greps: no old `{under,right}` pinned shape left, price only via `hasPrice`, storage helpers fine) and squash-merged as `80a40bb`; branch deleted. Parent pointer bumped. Still open: version 2.2.0 + `npm run audit` + tag `v2.2.0` (PR does not bump `package.json`); F-010/F-011 have no briefs (recorded here and in the F-009 log).
- 2026-10-16: F-012 backend (F012-B1..B3) **in progress** on `feature/F-012-list-icons-trash` (worktree `../backend-f012`): Haiku workers code only, gate + `make test-backup` once at the end, one PR, then tags `api-v0.8.0` / `v1.4.0`.
- 2026-10-16: F-012 backend (F012-B1..B3) **done**: [backend#25](https://github.com/0xfederama/collections-app-backend/pull/25) squash-merged `d775d6b`; tags `api-v0.8.0` and `v1.4.0` pushed; `make check` + `make test-backup` (AT-17) green; `make audit` clean; branch and worktree deleted. List `icon`/`icon_color`, `DELETE /trash`, setting `trash_retention_days` (daily auto-purge). Next: web F012-W1..W4 (pin to `api-v0.8.0`).
