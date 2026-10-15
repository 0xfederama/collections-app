# F-001 — 1.0 release readiness

Status: **done** (run with v1; v1.0.0 tagged 2026-10-15)    Release: 1.0    Roadmap: ROADMAP.md §5
Repos: backend, web, parent

> The v1 orchestrators finish this feature as Q-04 (done), Q-05 and C4, tracked in STATUS.md "Now: 1.0 release checks".
> This brief is only a summary and a checklist source for Q-05. Stories B0/W0 (adopting the v2 agents) become the first
> step of the **first v2 feature** instead.

## Why
The MVP is feature-complete (all B-, W- and Q-03 tasks merged). Before real data goes on the home server, we need
proof that someone new can set it up from the docs alone, a final scope and security pass, and your own walk-through.

## User stories
### Both repos, first (bootstrap of workflow v2, do before anything else)
- **F001-B0 / F001-W0**: As a repo orchestrator, I have the v2 agents installed, so workers run on Sonnet 5.5 at medium effort.
  Acceptance, one small `chore/adopt-workflow-v2` PR per repo:
  - copy `/Users/federico/Developer/collections-app/design-docs/templates/agents/worker.md` to `.claude/agents/worker.md`
  - delete `.claude/agents/test-writer.md` (retired in v2)
  - replace the "Dispatch cheaper subagents" bullet in `CLAUDE.md` with the v2 block from `templates/CLAUDE.<backend|web>.md`
  - check that `/agents` lists `worker` with model sonnet; if `effort` isn't accepted in agent frontmatter, flag it and pass `effort: "medium"` on every worker dispatch instead
  This is the orchestrator's own work, no worker needed.

### Backend (owns the fresh-clone run, because it spans parent + backend docs)
- **F001-B1** (was Q-04; a v1 worker session was already running it on 2026-10-15, branch `docs/Q-04-readme-fixes`: take over from its PR and its notes in handoffs/Q-04.md): As a new maintainer, I can clone the repo and reach a working dev, test and prod app by following
  only `README.md` → `deploy/README.md` → the service READMEs, so setup knowledge doesn't live in anyone's head.
  Acceptance: the full spec is in `/Users/federico/Developer/collections-app/design-docs/handoffs/Q-04.md` (rules of the
  exercise, checks, AT-01). Doc fixes: parent files committed by pathspec (D-044); backend README fixes in a backend PR;
  web README gaps reported to the web orchestrator (or fixed in a web PR, if trivial).
- **F001-B2** (was Q-05, backend half): As the owner, I know the backend ships nothing out of scope and nothing insecure.
  Acceptance: AT-19 scope fence (ORCHESTRATOR_BRIEF §2) checked against the code; ARCHITECTURE §5 checklist (upload
  validation, file serving headers, URL validation, no leaks of SQL/paths/stack traces, 127.0.0.1-only exposure,
  no secrets in the repo); `make audit` (govulncheck) clean or findings triaged. Findings: fixed in a PR, or listed in STATUS.md with severity.

### Web
- **F001-W1** (was Q-05, web half): As the owner, I know the web app ships nothing out of scope and nothing insecure.
  Acceptance: AT-19 scope fence; Markdown rendering without raw HTML plus URL sanitizing; CSP in the production image
  (D-072) has no unsafe relaxations; no `fetch` outside `lib/api`; `npm run audit` clean or triaged; no secrets in the
  bundle. Findings: fixed in a PR, or listed in STATUS.md with severity.

### You (product owner)
- **F001-U1** (C4): walk the smoke checklist at the end of `ACCEPTANCE_TESTS.md` on `./deploy/test up -d --fresh`, then on
  `./deploy/prod`, on desktop and phone width, light and dark. Note pass/fail per line in STATUS.md (or tell the top-level orchestrator).
- **F001-U2**: one real backup → wipe → restore on the dev stack (left open by Q-02).

### Parent (top-level orchestrator)
- **F001-P1**: after U1 passes, tag `v1.0.0` in both service repos and the parent (ask before pushing tags), mark 1.0
  shipped in ROADMAP.md, and promote F-002 / F-003 to briefs.

## Contract impact
None. `api-v0.2.0` stays.

## Constraints and decisions already made
- Review stories (B2, W1) are **orchestrator work, not workers'**: they're security-sensitive (AGENT_WORKFLOW §2). The
  orchestrator may use workers only for the mechanical parts (running audits, grepping) and for fixes.
- No new features. Fixes stay minimal; anything bigger becomes a roadmap item.

## Out of scope
- E2E tests (F-003), CI (F-003), UI changes (F-002), EXIF stripping (F-005).

## Open questions
| ID | Question | Default |
|---|---|---|
| — | — | — |

## Repo breakdown (filled by the repo orchestrators)
### Backend
| Task | Story | Branch | Worker result | Flags reviewed | PR |
|---|---|---|---|---|---|
### Web
| Task | Story | Branch | Worker result | Flags reviewed | PR |
|---|---|---|---|---|---|

## Log
- 2026-10-15: Brief written by the top-level orchestrator; v1 tasks Q-04 and Q-05 folded in.
- 2026-10-15: Done. Q-04 (backend#14), Q-05 (backend#15), C4 (items 1–13 PASS). v1.0.0 tagged. Findings → F-006.
