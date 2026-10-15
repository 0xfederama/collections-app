# Status Board

Living progress tracker shared by every session (AGENT_WORKFLOW §7). **Re-read right before editing**, change only your
own rows, and use dates. Task IDs and dependencies are in [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md).

States: `todo` · `in progress` · `in review` (PR open) · `blocked` · `done` (PR merged)

## Now: workflow v2 (from 2026-10-15, D-074)

**v1.0.0 is tagged** (backend `ea0b1c5`, web `2b9e7a6`, parent). Roadmap: [`ROADMAP.md`](../ROADMAP.md).
Feature briefs: [`features/`](features/). Repo orchestrators add their task rows under their feature.

| Feature | Story | Owner | State | Branch | PR | Updated | Notes |
|---|---|---|---|---|---|---|---|
| F-000 | F000-B1 install v2 agents + rules | backend orch. | done | `chore/adopt-workflow-v2` | [backend#16](https://github.com/0xfederama/collections-app-backend/pull/16) | 2026-10-15 | Squash-merged `f918264`, pointer bumped. Gate green. Smoke ran as an equivalent sonnet/medium dispatch (registry didn't reload mid-session); the next backend session confirms a native `worker` dispatch |
| F-000 | F000-W1 install v2 agents + rules | web orch. | done | `chore/adopt-workflow-v2` | [web#16](https://github.com/0xfederama/collections-app-frontend-web/pull/16) | 2026-10-15 | Squash-merged `5dc2586`, pointer bumped. Gate green (1200 tests). Smoke worker ran on Sonnet 5.5. The running session picks up a new agent file after a short delay (no restart needed) |
| F-006 | 1.0.1 polish (W1–W9) | web orch. | approved, not started | | | 2026-10-15 | C4 + Q-05 + Q-04 findings + user: Trash/Home stale after delete, backend status → Settings |

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
| backend | https://github.com/0xfederama/collections-app-backend | `/Users/federico/Developer/collections-app/backend` (submodule) | `api-v0.2.0` (`98d3b87`) |
| web | https://github.com/0xfederama/collections-app-frontend-web | `/Users/federico/Developer/collections-app/frontend-web` (submodule) | pinned: — |
| parent | https://github.com/0xfederama/collections-app | `/Users/federico/Developer/collections-app` | — |

## Waiting on the user

- Q-4 license (DECISIONS.md). Default applies if unanswered.

## Log (newest first, one line each)

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
