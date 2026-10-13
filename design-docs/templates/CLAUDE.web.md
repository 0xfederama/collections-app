# CLAUDE.md — collections-app-frontend-web

React + TypeScript + Vite web app for the Collection App. It consumes the backend API through a **vendored, pinned** OpenAPI spec.

## Design docs (canonical, read before working)

`/Users/federico/Developer/collections-app/design-docs/`. Always use this **absolute** path (worktrees break `../`).
- Every session: `AGENT_WORKFLOW.md`, then `STATUS.md` and `DECISIONS.md` (open questions + recent entries).
- These are **living, unversioned** docs. Update `STATUS.md` when you start or finish a task or open a PR, and record decisions as they happen (AGENT_WORKFLOW §7). Re-read before editing, and make small targeted edits.
- Web work: `UI_SPEC.md`, `API.md`, `PRODUCT.md`, `ARCHITECTURE.md` §3, and the task in `IMPLEMENTATION_PLAN.md`.
- If the code must deviate from the docs, follow AGENT_WORKFLOW §7. Never deviate silently.
- **Contract gaps:** don't work around them in the client. Ask the orchestrator or user to open a backend task (AGENT_WORKFLOW §6).

## Session rules (summary of AGENT_WORKFLOW)

- **Never push to `main`.** Branch `<feature|fix|hotfix|refactor|test|docs|chore|ci>/<desc>` from `origin/main`, use Conventional Commits, push the branch, and open a PR with `gh pr create`. Don't merge unless the user says so.
- **Dispatch cheaper subagents** (`.claude/agents/`):
  - `researcher` (sonnet): library docs and versions, a11y patterns. Must cite sources.
  - `test-writer` (sonnet): Vitest and Playwright tests. **You review and run them yourself.**
  - `docs-keeper` (haiku): updates `docs/` before every PR.
  - Built-in `Explore` handles broad code search.
  - Keep conflict UX, data flow, and design-system decisions in the main session.
- Update **this file** in the same PR when commands, layout, conventions, or gotchas change. Keep it under ~200 lines.
- MVP scope fence: no auth, TMDB, AI, WebSockets, or offline features (ORCHESTRATOR_BRIEF §2).

## Commands
<!-- Fill in at W-00 and keep exact. -->
| Purpose | Command |
|---|---|
| All checks (format, lint, types, tests, api drift) | `npm run check` |
| Dev server (:5173) | `npm run dev` |
| Unit/component tests | `npm test` |
| E2E (needs backend running) | `npm run test:e2e` |
| Sync API contract to a backend tag | `npm run api:sync -- api-v0.N.0` |
| Verify contract + generated client | `npm run api:check` |
| Production build / preview | `npm run build` / `npm run preview` |

## Layout & conventions
- `src/features/<feature>/` holds components, hooks, and `api.ts` (TanStack Query hooks). All server I/O goes through `src/lib/api`, never raw `fetch`.
- `src/generated/` is generated, so **never edit** it. Regenerate with `api:sync`.
- `src/components/ui/` is the design-system primitives. Use tokens from `src/styles/tokens.css`, with no hard-coded colors, radii, or spacing.
- Editable resources: `If-Match` is built from the resource `version` by `lib/api`. Drafts are never discarded on 412 or network errors (UI_SPEC §9).
- Accessibility is required: labels, focus-visible, keyboard paths, and no color-only state.
- Tests: names reference acceptance IDs (`describe("AT-13 external links")`). Mock the API with MSW handlers built from spec examples.

## Gotchas
<!-- Add entries as discovered: one line each, with the date. -->

## Working guidelines

### Shell
- Check the parent directory exists before creating files or directories. Quote paths with spaces (`"path with spaces/file"`).
- Prefer absolute paths over `cd`. Chain commands with `&&` or `;`, not newlines.
- Use the Read/Grep/Glob tools instead of `cat`/`grep`/`find`/`ls`. If shell search is unavoidable, use `rg`.
- Give every command a clear 5–10 word description. Use `run_in_background` for dev servers and watchers, never `sleep`.

### Proactiveness
- Do what was asked, including natural follow-ups (tests, docs, CLAUDE.md), but don't surprise the user with unrequested actions. If asked *how*, answer first.
- **Never guess.** Don't guess that a component, hook, or prop exists, a type, that tests pass, or business-logic flows. Verify in code or docs, or ask.

### Conventions
- Mimic the surrounding code style and look at existing components before creating new ones.
- Never assume a library is available. Check `package.json` first, and justify any new dependency in the PR.
- Security: never log or commit secrets. `.env` is gitignored, and `.env.example` holds placeholders only. Never render raw HTML from user content.
