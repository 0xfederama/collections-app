# F-000 — Workflow v2 bootstrap

Status: approved    Release: — (tooling)    Roadmap: — (process, D-074)
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
### Web
| Task | Story | Branch | Worker result | Flags reviewed | PR |
|---|---|---|---|---|---|

## Log
- 2026-10-15: Brief written by the top-level orchestrator (stories B0/W0 moved here from F-001).
