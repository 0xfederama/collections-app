# Handoff Briefs (v1 record)

> **Since 2026-10-15 (D-074) no new handoff briefs are written.** New work starts from a feature brief in
> [`../features/`](../features/), and the repo orchestrator dispatches internal `worker` agents. Existing briefs stay as a record
> (and as specs where a feature brief links to them, e.g. Q-04.md).

The repo orchestrator writes one file per task, `<TASK-ID>.md` (e.g. `B-06.md`), before a worker session starts it.
See AGENT_WORKFLOW §1b. Workers read their brief first and update its **Progress** and **Questions** sections.
Done briefs stay here as a record (state `done` in the header).

## Template

```markdown
# <TASK-ID> — <title>

Repo: backend | web    State: todo | in progress | in review | blocked | done
Branch: <type>/<TASK-ID>-<desc>  (from origin/main)    PR: —
Depends on (merged): <IDs / PRs>    Must not touch: <files owned by parallel tasks>

## Goal
<2–4 sentences: what exists when this is done>

## Read first
- design-docs sections: <e.g. DATA_MODEL §4, API §5 Trash>
- code: <files/packages to read and mimic>

## Scope
- <concrete deliverables, endpoints, components>
## Out of scope
- <things the worker must not do, even if tempting>

## Acceptance
- <AT ids + concrete checks>; `make check` / `npm run check` green

## Subagent plan
- researcher (sonnet): <questions, if any>
- test-writer (sonnet): <what to test>
- docs-keeper (haiku): before the PR

## Notes from the orchestrator
<gotchas, decisions already made, links to related PRs>

## Progress (worker)
## Questions (worker → orchestrator/user)
```
