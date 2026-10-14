# Status Board

Living progress tracker shared by every session (AGENT_WORKFLOW §7). **Re-read right before editing**, change only your
own rows, and use dates. Task IDs and dependencies are in [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md).

States: `todo` · `in progress` · `in review` (PR open) · `blocked` · `done` (PR merged)

## Current milestone: M1 — Contracts (C0 reached 2026-10-14)

M1/M2 web rows (added by the web orchestrator):

| Task | Repo | State | Branch | PR | Updated | Notes / blockers |
|---|---|---|---|---|---|---|
| W-03 | web | done | `feature/W-03-design-system` | [#2](https://github.com/0xfederama/collections-app-frontend-web/pull/2) | 2026-10-14 | Squash-merged as `320208c`; `npm run check` re-run green on main. Branch and worktrees removed |
| W-02 | web | done | `feature/W-02-api-client` | [#3](https://github.com/0xfederama/collections-app-frontend-web/pull/3) | 2026-10-14 | Squash-merged as `39d81ff` (D-058). Branch and worktree removed. `VITE_API_MOCKS=1` dev not yet tried in a real browser |
| W-04 | web | done | `feature/W-04-app-shell` | [#4](https://github.com/0xfederama/collections-app-frontend-web/pull/4) | 2026-10-14 | Squash-merged as `8b6110a`. Branch and worktree removed. Breadcrumbs owned by the shell (UI_SPEC §3 amended) |
| W-05 | web | done | `feature/W-05-tree-actions` | [#5](https://github.com/0xfederama/collections-app-frontend-web/pull/5) | 2026-10-14 | Squash-merged as `c812c9d`. Branch and worktree removed. Open: VoiceOver pass on "Picked up…" announcement; no right-click/Shift+F10 menu (More button instead) |
| W-06 | web | done | `feature/W-06-list-view` | [#6](https://github.com/0xfederama/collections-app-frontend-web/pull/6) | 2026-10-14 | Rebased on W-05, squash-merged as `89e045c` (D-063). Branch and worktree removed. Follow-ups (panel close keeps query, lazy routes) moved to W-07 |
| W-07 | web | in progress | `feature/W-07-item-detail` | — | 2026-10-14 | brief: handoffs/W-07.md. Parallel with W-11. Then W-08 |
| W-11 | web | in progress | `feature/W-11-search` | — | 2026-10-14 | brief: handoffs/W-11.md. Parallel with W-07. B-11 is merged (08d30ab), so also test against the real backend |

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
| B-10 | backend | in progress | `feature/B-10-trash` | — | 2026-10-14 | brief: handoffs/B-10.md. Runs alone; last backend feature task. D-065 |
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
- The parent `compose.yaml` (web on `127.0.0.1:5173`) is not covered by the AT-18 script, which only renders the backend
  compose. Q-03's production compose must get its own exposure check.
- GitGuardian scans every push: no `user:pass@host` strings, blank secrets in examples (see backend CLAUDE.md gotchas).
- Parent commits go straight to `main` by pathspec (D-044). Service repos are PR-only; the user merges.

## Repos

| Repo | Remote | Local path | Latest API tag |
|---|---|---|---|
| backend | https://github.com/0xfederama/collections-app-backend | `/Users/federico/Developer/collections-app/backend` (submodule) | `api-v0.1.0` (`ae8ae4e`) |
| web | https://github.com/0xfederama/collections-app-frontend-web | `/Users/federico/Developer/collections-app/frontend-web` (submodule) | pinned: — |
| parent | https://github.com/0xfederama/collections-app | `/Users/federico/Developer/collections-app` | — |

## Waiting on the user

- Q-4 license (DECISIONS.md). Default applies if unanswered.

## Log (newest first, one line each)

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
