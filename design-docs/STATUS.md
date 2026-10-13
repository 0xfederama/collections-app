# Status Board

Living progress tracker shared by every session (AGENT_WORKFLOW §7). **Re-read right before editing**, change only your
own rows, and use dates. Task IDs and dependencies are in [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md).

States: `todo` · `in progress` · `in review` (PR open) · `blocked` · `done` (PR merged)

## Current milestone: M0 — Bootstrap

| Task | Repo | State | Branch | PR | Updated | Notes / blockers |
|---|---|---|---|---|---|---|
| M0-U | — | done | — | — | 2026-10-13 | Repos created and cloned. License still open (Q-4) |
| R-1 | both | done | — | — | 2026-10-13 | Versions + D-035–D-042 in DECISIONS.md |
| R-2 | backend | done | — | — | 2026-10-13 | OpenAPI 3.0.3, oapi-codegen, Redocly (D-041) |
| B-00 | backend | in review | `chore/B-00-skeleton` | [#1](https://github.com/0xfederama/collections-app-backend/pull/1) | 2026-10-13 | `make check` + compose verified. Awaiting your review |
| B-01 | backend | dropped | — | — | 2026-10-13 | No CI for now (D-031); local `make check` from B-00 |
| W-00 | web | in review | `chore/W-00-skeleton` | [#1](https://github.com/0xfederama/collections-app-frontend-web/pull/1) | 2026-10-13 | `npm run check` + dev proxy verified. Awaiting your review |
| W-01 | web | dropped | — | — | 2026-10-13 | No CI for now (D-031); local `npm run check` from W-00 |

## Repos

| Repo | Remote | Local path | Latest API tag |
|---|---|---|---|
| backend | https://github.com/0xfederama/collections-app-backend | `/Users/federico/Developer/collections-app/backend` (submodule) | — |
| web | https://github.com/0xfederama/collections-app-frontend-web | `/Users/federico/Developer/collections-app/frontend-web` (submodule) | pinned: — |
| parent | https://github.com/0xfederama/collections-app | `/Users/federico/Developer/collections-app` | — |

## Waiting on the user

- Q-4 license, Q-6 visual direction (DECISIONS.md). Defaults apply if unanswered.

## Log (newest first, one line each)

- 2026-10-14: Parent repo `0xfederama/collections-app` created (D-043): backend/ and frontend-web/ are submodules pinned to the open skeleton PR branches (backend#1, web#1 still unmerged). Docs now versioned in the parent. After each service PR merges, bump the pointer to the merged `main` commit.

- 2026-10-13: GitGuardian flagged backend#1 (password-shaped strings in `.env.example`, `compose.yaml`, Makefile, tests). Fixed by blank secret values in examples, credentials as `?user=&password=` query params, and plain `${POSTGRES_PASSWORD}` in compose; branch amended + force-with-lease (history clean), check now passes. The earlier incident may still be open in the GitGuardian dashboard (user can resolve it).

- 2026-10-13: M0 session: R-1/R-2 done (3 sonnet researchers). User chose Radix per-primitive and TS 6.0.3. `migrate up` on an empty dir exits 1 (verified), so compose uses a guard (D-037). Starting B-00.
- 2026-10-13: B-00 and W-00 PRs opened (backend#1, web#1), both local checks green. Waiting for the user's review; not merged.

- 2026-10-13: M0 replanned: local-only gates, no GitHub CI or Dependabot, PRs only for user code review, backend in one compose, web via Vite with an `/api` proxy, lean frontend (D-031–D-034). B-01/W-01 dropped. Brief: handoffs/M0.md.

- 2026-10-13: Workflow set: one setup session (M0, both repos), then a repo orchestrator per repo that writes `handoffs/<ID>.md` briefs, then worker sessions (one task, one worktree, one PR) — AGENT_WORKFLOW §1b.

- 2026-10-13: Design package v1 written. Kinds, dark theme, repo names, and the unversioned-docs policy were decided (D-026–D-030).
