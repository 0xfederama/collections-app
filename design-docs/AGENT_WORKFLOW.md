# Agent Workflow

Every session in `collections-app-backend` or `collections-app-frontend-web` follows this document. Each repo's `CLAUDE.md`
links here. CLAUDE.md is loaded automatically at session start, so it carries the short version of these
rules, and this file has the full version.

---

## 1. Session start checklist

1. Read the repo's `CLAUDE.md` (auto-loaded) and this file.
2. Read `STATUS.md` (what's in progress, blocked, or next) and `DECISIONS.md` (at minimum the open questions and the last ~10 entries).
3. Identify the task ID from `IMPLEMENTATION_PLAN.md` (or the user's request), mark it `in progress` in `STATUS.md`, and read only the design docs it references.
4. Run `git fetch origin && git status`. If you are on `main`, create a branch before editing anything (§3).
5. Plan the work and decide which parts to **dispatch to cheaper subagents** (§2) before you start.

---

## 1b. Session types: setup → repo orchestrators → workers

| Session | Where | Lifetime | Does |
|---|---|---|---|
| **Setup** | `/Users/federico/Developer/collections-app` (both repos) | Once | M0 for both repos (research, skeletons, CI, CLAUDE.md, agents), with one PR per repo task |
| **Repo orchestrator** | one per repo | Long-lived, one per milestone if context grows | Plans the next tasks, writes **handoff briefs**, gives the user worker prompts, reviews worker PRs against the design docs, keeps STATUS.md, coordinates cross-repo contract changes. Implements only small glue or fixes itself |
| **Worker** | one per task, in its **own git worktree** | One task = one branch = one PR | Reads its brief, implements, tests, opens the PR, updates STATUS.md, then ends |

### Handoff briefs
- The orchestrator writes one brief per task to `design-docs/handoffs/<TASK-ID>.md` (template: `handoffs/README.md`) **before** the user starts the worker. The brief has to be complete on its own: the worker has no context except CLAUDE.md, the design docs, and the brief.
- Only hand off tasks whose dependencies are **merged** (or explicitly noted as "branch from X"). Tasks running in parallel must not touch the same foundational files (ORCHESTRATOR_BRIEF §5).
- The orchestrator records each handed-off task in STATUS.md as `todo` with `brief: handoffs/<ID>.md`. The worker flips it to `in progress` → `in review`.
- When a worker hits a design gap, it writes the question in the brief's "Questions" section and in STATUS.md (`blocked`), then asks the user. It does not guess.

### Parallel sessions in one repo
- Every worker runs in its **own git worktree** (the desktop app's worktree option, or `git worktree add ../<repo>-<task> -b <branch> origin/main`, run from inside the submodule (`backend/` or `frontend-web/`)). Never have two sessions share a working tree.
- Design docs are always referenced by absolute path, which works from any worktree.
- After a PR merges, other open branches rebase onto `origin/main` before continuing.

---

## 2. Model dispatch policy (cost control)

The main session (the orchestrator, normally the most capable model) owns design judgment, complex
implementation, integration, and final review. It **delegates** cheaper work to subagents defined in
each repo's `.claude/agents/` (templates in `design-docs/templates/agents/`).

| Work | Agent | Model | Notes |
|---|---|---|---|
| Codebase search ("where is X", "what calls Y") | built-in `Explore` or `researcher` | haiku / sonnet | Ask for conclusions plus file:line, not file dumps |
| Web/doc research (current versions, library status, API docs, TMDB terms later) | `researcher` | **sonnet** | Must cite sources and give the date checked. Never guess versions |
| Writing unit/integration tests for existing or just-written code | `test-writer` | **sonnet** | Main session reviews the tests and **runs them itself**. Never accept "tests pass" without running them |
| Updating the repo's simple service docs (`docs/`), README sections, CHANGELOG lines | `docs-keeper` | **haiku** | Runs before every PR is opened (§5) |
| Mechanical, well-specified edits (renames, boilerplate from a clear pattern) | `general-purpose` with `model: sonnet` | sonnet | Give exact files and the pattern to follow |
| Architecture, schema, API design, concurrency/trash/storage logic, security-sensitive code, PR self-review | main session | top model | Do not delegate |

Dispatch rules:
- **Prompts must be self-contained.** A subagent starts with no context. Include file paths, the relevant design-doc section, acceptance criteria, and the expected output format.
- Run independent subagents **in parallel** (e.g. researcher plus test-writer on different modules).
- Do not delegate tasks whose output you would need to fully re-derive to trust.
- If a cheap agent's output is wrong twice, do the task in the main session instead.
- Subagents do not push, open PRs, or edit `CLAUDE.md`. The main session does those.

---

## 3. Git & PR rules (mandatory)

- **Never push to `main`.** Every change goes through a PR the user reviews. There's no CI for now (D-031/D-032): run `make check` / `npm run check` yourself before opening the PR and paste the result. Never force-push `main`.
- Branch from an up-to-date `origin/main`: `git switch -c <type>/<short-kebab-description> origin/main`
- Branch types:

  | Prefix | Use |
  |---|---|
  | `feature/` | New functionality |
  | `fix/` | Non-urgent bug fix |
  | `hotfix/` | Urgent fix for a broken `main` or a deployed release |
  | `refactor/` | No behavior change |
  | `test/` | Tests only |
  | `docs/` | Docs / CLAUDE.md only |
  | `chore/` | Deps, tooling, config |
  | `ci/` | GitHub Actions / pipeline |

  Optionally include the plan task ID: `feature/B-07-trash-restore`.
- Commits: [Conventional Commits](https://www.conventionalcommits.org/) (`feat(items): add image upload`), small and focused.
- Push your branch to `origin` and open a PR with `gh pr create` using `.github/pull_request_template.md`.
- One concern per PR, sized for review (aim for under ~600 changed lines excluding generated code).
- `--force-with-lease` is allowed **only** on your own unmerged branch. Rebasing on `main` is preferred over merge commits.
- **Do not merge PRs yourself** unless the user explicitly authorized it for that PR. The user reviews and merges.
- Never commit secrets, `.env`, real user data, or the local `data/` directories.

### PR checklist (copy in the template)
- [ ] `make check` (backend) / `npm run check` (web) passes locally
- [ ] Tests added/updated and run by the main session
- [ ] `CLAUDE.md` updated if commands, conventions, layout or gotchas changed
- [ ] `docs/` updated by `docs-keeper`
- [ ] API change? Followed §6 contract protocol
- [ ] Migration? Up/down tested on a fresh DB and a DB with data
- [ ] No scope creep beyond the task (see ORCHESTRATOR_BRIEF §3)

---

## 4. CLAUDE.md upkeep

Each repo keeps a `CLAUDE.md` (template: `templates/CLAUDE.backend.md` / `templates/CLAUDE.web.md`) **plus** a `README.md`:

- `README.md` is for humans: setup, run, test, troubleshoot.
- `CLAUDE.md` is for agents: link to the design docs, exact commands, conventions, layout, gotchas, and the dispatch and git rules summary.

Update `CLAUDE.md` in the **same PR** as any change to commands, layout, conventions, tooling, or any gotcha you
spent more than ~10 minutes on. Keep it short (under ~200 lines). Link to docs rather than duplicating them.

---

## 5. Simple in-repo service docs (kept up to date by `docs-keeper`, haiku)

Each repo has a deliberately **minimal** `docs/` folder:

```text
docs/
├── README.md            # index: one line per module
└── modules/<name>.md    # one per backend package / frontend feature
```

Each module doc is at most ~40 lines with exactly these sections: **Purpose**, **Key files**,
**Interfaces** (endpoints / exported functions / components), **Gotchas**. No prose essays, no
duplication of design docs (link instead).

Before opening every PR, the main session dispatches `docs-keeper` with the diff summary (`git diff origin/main --stat` plus a short description). It updates or creates only the affected module docs.

---

## 6. Cross-repo API contract protocol

- The backend owns `api/openapi.yaml`. The frontend keeps a **vendored copy** at `api/openapi.yaml`, plus `api/openapi.lock.json` (`{ "backendRef": "<tag or commit sha>", "sha256": "<hash of yaml>" }`).
- `npm run api:sync -- <ref>` fetches the spec at that backend ref, updates the lock file, and regenerates `src/generated/`.
- `npm run check` (via `api:check`) fails if the hash doesn't match or the generated code is stale (local gate, D-031).
- Changes must be **additive first** (expand/contract): add fields or endpoints → frontend adopts them → remove the old ones in a later backend PR.
- A breaking change needs a "Contract change" section in the backend PR listing affected endpoints, rollout order, and the frontend follow-up task. The orchestrator creates the matching frontend task.
- Backend tags contract milestones as `api-v0.N.0` so the frontend pins to tags, not random commits.

---

## 7. Keeping the design docs current (living docs, versioned in the parent repo)

`design-docs/` is a **living planning workspace** shared by all sessions in both repos. It is intentionally **not** under
git, and it is **not** the documentation of the services (that lives in each repo's `README.md`, `CLAUDE.md`, and `docs/`).
Because it is the shared coordination point, keep it updated **frequently**:

- **When you start a task:** set it to `in progress` in [STATUS.md](STATUS.md) with your branch name.
- **When you open or merge a PR, or get blocked:** update STATUS.md (PR link, state, blocker).
- **When a decision is made or the implementation deviates from a doc:** add a `DECISIONS.md` entry **and** update the affected doc right away, in the same session. Mention it in the PR description. Contract changes (API.md, DATA_MODEL.md) always need a DECISIONS.md entry.
- **When you discover something future sessions need** (a new task, a dependency between tasks, a cross-repo gap): add it to IMPLEMENTATION_PLAN.md or STATUS.md.
- Ask the user first for changes that alter product behavior, scope, security, or UX in a meaningful way.

Since there is no git history to fall back on, edit safely:
- **Re-read** the section right before editing it, because another session may have changed it.
- Make **small targeted edits** (Edit tool) and never rewrite whole files.
- Never delete other sessions' entries. Mark them superseded or done instead.
- Use dates (YYYY-MM-DD) on status and decision entries.

---

## 8. General working rules (from the user's standard CLAUDE.md notes)

- **Never guess.** Don't assume a method, class, library, version, or business rule exists. Check the code, the docs, or the dependency manifest. Ask the user when in doubt. Never claim tests pass without running them.
- **Follow conventions.** Read neighboring files and imports first. Reuse existing utilities and libraries. Never add a dependency without checking it is not already covered, and note new dependencies in the PR.
- **Shell hygiene.** Quote paths with spaces. Prefer absolute paths over `cd`. Use the dedicated Read/Grep/Glob tools over `cat`/`grep`/`find`. If shell search is unavoidable, use `rg`. Chain commands with `&&`/`;`. Check that the parent directory exists before creating files.
- **Proactiveness.** Do what was asked, including obvious follow-ups (tests, docs). Don't surprise the user with unrequested actions. If the user asks *how* to do something, answer first.
- **Security.** Never log or commit secrets. Never expose filesystem paths, SQL, or stack traces in API responses. Never bind the API publicly without auth (see PRODUCT §7).
