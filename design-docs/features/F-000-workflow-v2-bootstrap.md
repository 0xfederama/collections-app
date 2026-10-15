# F-000 — Workflow v2 bootstrap

Status: **done** (backend#16, web#16 merged 2026-10-15)    Release: — (tooling)    Roadmap: — (process, D-074)
Repos: backend, web    Approved by the user: 2026-10-15 ("start v2")

## Why
v2 repo orchestrators dispatch `worker` agents that run on Sonnet 5.5 at medium effort. The service repos still carry the
v1 agents (`test-writer`) and v1 rules in `CLAUDE.md`. This installs v2 in each repo, so every later feature runs the same way.

## User stories
### Backend
- **F000-B1**: As the backend orchestrator, I have the v2 agents and rules in the repo, so workers run on Sonnet 5.5 medium and report FLAGS.
  Acceptance, one `chore/adopt-workflow-v2` PR:
  - `.claude/agents/worker.md` = a copy of `/Users/federico/Developer/collections-app/design-docs/templates/agents/worker.md`
  - `.claude/agents/test-writer.md` deleted (retired in v2)
  - in `CLAUDE.md`, the "Dispatch cheaper subagents" bullet is replaced by the "Workflow v2" block from
    `/Users/federico/Developer/collections-app/design-docs/templates/CLAUDE.backend.md`; other references to `test-writer` are removed
  - a smoke dispatch: a `worker` with a trivial read-only task ("list the Makefile targets, change nothing") returns the
    report format. Confirm it ran on Sonnet. If `effort` isn't accepted in the agent frontmatter, flag it, remove the
    key, and note in `CLAUDE.md` that each dispatch passes `effort: "medium"`
  - `make check` green
### Web
- **F000-W1**: the same for the web repo, with `templates/CLAUDE.web.md`, and `npm run check` green.

## Contract impact
None.

## Constraints and decisions already made
- AGENT_WORKFLOW §1b and §2 (v2), D-074. This is the orchestrator's own small change: no worker needed (except the smoke dispatch).

## Out of scope
- Any code change. Any other `CLAUDE.md` rewrite beyond the dispatch block.

## Repo breakdown (filled by the repo orchestrators)
### Backend
| Task | Story | Branch | Worker result | Flags reviewed | PR |
|---|---|---|---|---|---|
| B1a copy `worker.md`, delete `test-writer.md`, swap the CLAUDE.md dispatch block (orchestrator, no worker) | F000-B1 | `chore/adopt-workflow-v2` | — | — | [backend#16](https://github.com/0xfederama/collections-app-backend/pull/16) merged `f918264` |
| B1b smoke dispatch (read-only Makefile targets) | F000-B1 | — | DONE, report format OK, ran on `claude-sonnet-5-5`, `FLAGS: none` | Equivalent dispatch (general-purpose + `worker.md` body, sonnet/medium), because the agent registry didn't reload mid-session. `effort` is a documented frontmatter key, kept. Open: the next backend session confirms that a native `worker` dispatch resolves | — |
### Web
| Task | Story | Branch | Worker result | Flags reviewed | PR |
|---|---|---|---|---|---|
| W1a install worker.md, delete test-writer, CLAUDE.md v2 block (orchestrator, no worker) | F000-W1 | `chore/adopt-workflow-v2` | — | — | [web#16](https://github.com/0xfederama/collections-app-frontend-web/pull/16) merged `5dc2586` |
| W1b smoke dispatch of `worker` (read-only) | F000-W1 | — | DONE, report format OK, ran on `claude-sonnet-5-5` (parent on Haiku); `effort` accepted | [UNVERIFIED] gate not run (read-only, expected) | — |

## Log
- 2026-10-15: Brief written by the top-level orchestrator (stories B0/W0 moved here from F-001).
