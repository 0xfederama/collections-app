# CLAUDE.md — collections-app-backend

Go REST API + PostgreSQL for the Collection App. It owns the canonical API contract `api/openapi.yaml`.

## Design docs (canonical, read before working)

`/Users/federico/Developer/collections-app/design-docs/`. Always use this **absolute** path (worktrees break `../`).
- Every session: `AGENT_WORKFLOW.md`, then `STATUS.md` and `DECISIONS.md` (open questions + recent entries).
- These are **living** docs, versioned in the **parent** repo (D-043). Update `STATUS.md` when you start or finish a task or open a PR, and record decisions as they happen (AGENT_WORKFLOW §7). Re-read before editing, and make small targeted edits. Commit design-doc edits in the parent, never in this repo (AGENT_WORKFLOW §7, D-044).
- Backend work: `DATA_MODEL.md`, `API.md`, `ARCHITECTURE.md` §2/§4/§5, and the task in `IMPLEMENTATION_PLAN.md`.
- If the code must deviate from the docs, follow AGENT_WORKFLOW §7. Never deviate silently.

## Session rules (summary of AGENT_WORKFLOW)

- **Never push to `main`.** Branch `<feature|fix|hotfix|refactor|test|docs|chore|ci>/<desc>` from `origin/main`, use Conventional Commits, push the branch, and open a PR with `gh pr create`. Don't merge unless the user says so.
- **Workflow v2 (AGENT_WORKFLOW §1b, D-074).** This session is the **repo orchestrator** (Opus 5.5, medium effort): it splits
  the repo's stories from `design-docs/features/F-NNN-*.md` into tasks and dispatches agents from `.claude/agents/`:
  - `worker` (Sonnet 5.5, medium): implements one task with its tests, runs the tests that matter, commits, and reports
    **FLAGS**. Review **only flagged items**, and run the full gate yourself once before each PR.
  - Run tests wisely (§1b "Test runs", D-076): targeted tests while working, the full gate once per PR, slow suites
    (e2e, smoke, backup round trip) only when the change touches what they cover or before a release.
  - `researcher` (sonnet): versions, library docs, "how does X work here". Must cite sources.
  - `docs-keeper` (haiku): updates `docs/` before every PR.
  - Built-in `Explore` handles broad code search.
  - Keep schema, concurrency, trash, storage, and security logic as `[CRUCIAL]` flags you always review.
- Update **this file** in the same PR when commands, layout, conventions, or gotchas change. Keep it under ~200 lines.
- MVP scope fence: no auth, TMDB, AI, public-API features, WebSockets, ORM, Redis, or queues (ORCHESTRATOR_BRIEF §2).

## Commands
<!-- Fill in at B-00 and keep exact. -->
| Purpose | Command |
|---|---|
| All checks (fmt, lint, test, generate-drift) | `make check` |
| Start DB | `docker compose up -d db` |
| Migrate | `make migrate` |
| Run API | `make run` |
| Tests | `make test` (needs Docker for testcontainers) |
| Regenerate sqlc + server stubs | `make generate` |
| New migration | `make migration name=<snake_case>` |

## Layout & conventions
- `cmd/api`: wiring only. `internal/<domain>`: services and domain errors. `internal/httpapi`: handlers, middleware, problem mapping. `internal/database/sqlc`: generated code, **never edit**.
- SQL lives in `db/queries/*.sql` (sqlc). Every query filters by `workspace_id`. Every UPDATE sets `updated_at` and, for editable resources, `version = version + 1`.
- Multi-statement writes go through `database.InTx`.
- Files: write before the tx, delete after commit (ARCHITECTURE §4).
- Errors: return typed domain errors, and map them to problem+json only in `httpapi`. Never leak SQL, paths, or stack traces.
- Tests: table-driven, with names prefixed by the acceptance-test ID when applicable (`TestAT10_…`). Integration tests use testcontainers Postgres and a `t.TempDir()` data dir.

## Gotchas
<!-- Add entries as discovered: one line each, with the date. -->

## Working guidelines

### Shell
- Check the parent directory exists before creating files or directories. Quote paths with spaces (`"path with spaces/file"`).
- Prefer absolute paths over `cd` (e.g. `go test /abs/path/...`). Chain commands with `&&` or `;`, not newlines.
- Use the Read/Grep/Glob tools instead of `cat`/`grep`/`find`/`ls`. If shell search is unavoidable, use `rg`.
- Give every command a clear 5–10 word description. Use `run_in_background` for long-running processes, never `sleep`.

### Proactiveness
- Do what was asked, including natural follow-ups (tests, docs, CLAUDE.md), but don't surprise the user with unrequested actions. If asked *how*, answer first.
- **Never guess.** Don't guess that a method exists, an object's type, that tests pass, or business-logic flows. Verify in code or docs, or ask.

### Conventions
- Mimic the surrounding code style, reuse existing helpers, and read imports before editing.
- Never assume a library is available. Check `go.mod` first, and justify any new dependency in the PR.
- Security: never log or commit secrets or keys. `.env` is gitignored, and `.env.example` holds placeholders only.
