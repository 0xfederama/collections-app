# Agent Workflow

Every session in `collections-app-backend` or `collections-app-frontend-web` follows this document. Each repo's `CLAUDE.md`
links here. CLAUDE.md is loaded automatically at session start, so it carries the short version of these
rules, and this file has the full version.

---

## 1. Session start checklist

1. Read the repo's `CLAUDE.md` (auto-loaded) and this file.
2. Read `STATUS.md` (what's in progress, blocked, or next) and `DECISIONS.md` (at minimum the open questions and the last ~10 entries).
3. Find your work: a **feature brief** in `features/F-NNN-*.md` (repo orchestrators), or the task prompt from your orchestrator
   (workers). Mark it `in progress` in `STATUS.md` (orchestrators only), and read only the design docs it references.
4. Run `git fetch origin && git status`. If you are on `main`, create a branch before editing anything (§3).
5. Plan the work and decide which parts go to **worker agents** (§2) before you start.

---

## 1b. Session types (v2, D-074, in effect since v1.0.0 on 2026-10-15)

Three levels. Only the top two are sessions the user starts. Workers are **internal subagents** of a repo orchestrator,
not separate sessions.

| Level | Where | Model | Does | Does not |
|---|---|---|---|---|
| **Top-level orchestrator** | parent repo root (`/Users/federico/Developer/collections-app`) | Opus 5.5, medium effort | Owns [`ROADMAP.md`](../ROADMAP.md). Analyzes each new feature with the user, writes the **feature brief** (`features/F-NNN-*.md`): why, user stories per repo, contract impact, out of scope. Keeps cross-repo order (backend contract first). Parent-repo changes (`deploy/`, docs, pointer bumps) | Split stories into tasks, write code in the service repos, review worker output |
| **Repo orchestrator** | one per repo, started in `backend/` or `frontend-web/` | Opus 5.5, **medium** effort | Turns its repo's stories into small tasks, dispatches **worker** agents, reviews **only what workers flag**, runs the repo gate, opens the PRs, updates STATUS.md and the brief's "Repo breakdown". Asks the top-level orchestrator (via the user) or the user about design gaps | Re-review unflagged work line by line |
| **Worker** (agent `worker`) | inside the repo orchestrator's session (Agent tool) | Sonnet 5.5, medium effort (set in `.claude/agents/worker.md`) | Implements one task with its tests, runs the gate, commits on the given branch, and ends with a report whose **FLAGS** section lists deviations, decisions, crucial points and anything unverified | Push, open PRs, edit CLAUDE.md or design docs, widen its scope |

### Flow of a feature
1. **You and the top-level orchestrator** discuss the idea. It writes `features/F-NNN-<slug>.md` (template: `features/README.md`)
   with user stories per repo, adds the feature to STATUS.md and ROADMAP.md, and you approve it.
2. **You start (or reuse) the repo orchestrators** with a one-line prompt: "Implement F-NNN, your stories" (see `features/README.md`).
3. **Each repo orchestrator** splits its stories into tasks (a few hours of work each), writes them into the brief's
   "Repo breakdown", and dispatches workers: one branch and PR per story by default, sequentially on that branch, or in
   parallel with `isolation: "worktree"` when tasks don't touch the same files. Backend contract changes merge (and get tagged)
   before the web stories that need them.
4. **Workers report.** `FLAGS: none` → the orchestrator only runs the repo gate (`make check` / `npm run check`) once
   before the PR (see "Test runs" below), and doesn't read the diff. Flagged items → it reviews exactly those points, fixes or accepts them, and
   records a D-entry when a flag is a real decision.
5. **PRs**: the repo orchestrator merges them itself once the gate is green (D-077): always squash, never a merge commit; a
   non-trivial rebase and its merge go to a Sonnet 5.5 subagent. The user can still read every PR. After the merge the repo orchestrator bumps the parent pointer (D-044) and updates STATUS.md.
   When all stories are done, the top-level orchestrator marks the feature shipped in ROADMAP.md.

### Rules that keep it cheap
- Worker prompts are **self-contained and short**: the story, the task, files to start from, acceptance criteria, the branch,
  and "end with the report format in your agent definition". Don't paste design docs; give their absolute paths and sections.
- The repo orchestrator never re-derives what a worker did unless it's flagged. If a worker's result is wrong twice, the
  orchestrator does that task itself.
- Security-sensitive, schema, contract (`api/openapi.yaml`), migration, concurrency, trash and storage work: the worker
  **must** flag it as `[CRUCIAL]`, and the orchestrator reviews those parts.
- `docs-keeper` (haiku) still updates `docs/` before every PR. `researcher` (sonnet) still handles version and library research.
- Running the app for a check: `./deploy/test up -d --fresh` from the parent, never the user's dev data.

### Test runs: wisely, not by reflex (D-076)
Run the smallest set of checks that proves the change. A full suite re-run is a tool, not a ritual.

| Situation | What to run |
|---|---|
| Worker, while working | The tests for the code it touches, plus the fast static checks (format, lint, types). |
| Worker, before reporting | Its targeted tests and the static checks, green. The **full gate** only when the task touches shared code: the API contract or generated client, schema/migrations/sqlc, shared query keys or hooks, build config, dependencies, Docker/compose/Caddy. The report's Verification says exactly what ran. |
| Orchestrator, before opening a PR | The full gate (`make check` / `npm run check`) **once**, on the final commit. Not after every worker, and not again if nothing changed since the last green run. |
| Docs, README or comment-only change | No tests. Formatting of the touched files at most. |
| Slow suites: e2e, smoke on `./deploy/test`, `make test-backup`, browser checks | Only when the change touches what they cover (backup scripts → `make test-backup`; compose, Dockerfile, Caddy or CSP → stack smoke; user flows → e2e), or before a release tag. Never "just in case". |
| A test fails and looks flaky | Re-run that test only, not the whole suite. |

"Never claim tests pass without running them" still holds: say what ran, and don't imply more.

### Parallel work in one repo
- Parallel workers use `isolation: "worktree"`. The orchestrator merges their branches into the story branch. Never let
  two agents edit the same working tree at once.
- Two **sessions** never share a working tree either. If the user runs a second session in a repo, it uses its own worktree,
  created from inside the submodule (`git worktree add ../<repo>-<task> -b <branch> origin/main`).
- Design docs are always referenced by absolute path, which works from any worktree.

### History
v1 (M0–M5 and the 1.0 release checks Q-04, Q-05, C4): setup session → repo orchestrators writing `handoffs/<ID>.md` → one **worker session** per
task in its own worktree. Superseded by v2 (D-074). The `handoffs/` folder is kept as a record.

---

## 2. Model dispatch policy (cost control)

| Work | Who | Model / effort | Notes |
|---|---|---|---|
| Feature analysis, user stories, cross-repo order, roadmap | top-level orchestrator | Opus 5.5 / medium | Session in the parent repo |
| Task breakdown, flagged-item review, contract and schema design, PRs | repo orchestrator | Opus 5.5 / medium | Session in `backend/` or `frontend-web/` |
| Implementation + its tests, mechanical edits, test fixes | `worker` | Sonnet 5.5 / medium | Ends with a FLAGS report |
| Web/doc research (versions, library status, API docs, TMDB terms) | `researcher` | sonnet | Must cite sources and give the date checked. Never guess versions |
| Codebase search ("where is X") | built-in `Explore` | haiku | Conclusions plus file:line, not file dumps |
| `docs/` module docs before every PR | `docs-keeper` | haiku | §5 |

Dispatch rules:
- **Prompts must be self-contained.** A subagent starts with no context.
- Run independent workers **in parallel** (worktree isolation).
- Subagents do not push, open PRs, or edit `CLAUDE.md` or design docs. The repo orchestrator does those.
- **Never claim tests pass without running them:** the orchestrator runs the repo gate itself once before each PR. Otherwise run tests wisely (§1b "Test runs", D-076).
- `test-writer` is retired in v2: workers write the tests for their own task.

---

## 3. Git & PR rules (mandatory)

- **Never push to `main` of a service repo** (`backend/`, `frontend-web/`). Every service change goes through a PR the user reviews. The **parent** repo is the exception: design docs, `compose.yaml`, README and pointer bumps are committed straight to its `main` (§7, D-044). There's no CI for now (D-031/D-032): run `make check` / `npm run check` yourself before opening the PR and paste the result. Never force-push `main`.
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
- **Merging (D-077):** in workflow v2 the repo orchestrator merges its own PRs once the gate is green: squash merge only
  (`gh pr merge --squash --delete-branch`), never merge commits. A non-trivial rebase and its merge go to a Sonnet 5.5
  subagent. Any other session merges only when the user explicitly says so for that PR.
- **After every merge, always delete the branch** locally (`git branch -D <branch>`) and on the remote (`git push origin --delete <branch>`), remove its worktree (`git worktree remove <path>`), then `git fetch --prune`. The orchestrator does this when it bumps the parent pointer (user rule, 2026-10-14).
- Never commit secrets, `.env`, real user data, or the local `data/` directories.

### PR checklist (copy in the template)
- [ ] `make check` (backend) / `npm run check` (web) passes locally
- [ ] Tests added/updated and run by the main session
- [ ] `CLAUDE.md` updated if commands, conventions, layout or gotchas changed
- [ ] `docs/` updated by `docs-keeper`
- [ ] API change? Followed §6 contract protocol
- [ ] Migration? Up/down tested on a fresh DB and a DB with data
- [ ] No scope creep beyond the task (see ORCHESTRATOR_BRIEF §2)

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

`design-docs/` is a **living planning workspace** shared by all sessions in both repos. It is tracked in the **parent**
repo `collections-app` (D-043), and it is **not** the documentation of the services (that lives in each repo's `README.md`,
`CLAUDE.md`, and `docs/`). Because it is the shared coordination point, keep it updated **frequently**:

- **When you start a task:** set it to `in progress` in [STATUS.md](STATUS.md) with your branch name.
- **When you open or merge a PR, or get blocked:** update STATUS.md (PR link, state, blocker).
- **When a decision is made or the implementation deviates from a doc:** add a `DECISIONS.md` entry **and** update the affected doc right away, in the same session. Mention it in the PR description. Contract changes (API.md, DATA_MODEL.md) always need a DECISIONS.md entry.
- **When you discover something future sessions need** (a new task, a dependency between tasks, a cross-repo gap): add it to IMPLEMENTATION_PLAN.md or STATUS.md.
- Ask the user first for changes that alter product behavior, scope, security, or UX in a meaningful way.

Committing design-doc edits (D-044). The parent repo has no PRs: commit straight to its `main`.
- Commit **only the files you edited**, by pathspec: `git -C /Users/federico/Developer/collections-app commit -m "docs: …" -- design-docs/STATUS.md …`.
  Never `git add -A` or `git commit -a` in the parent: it would sweep up other sessions' edits and submodule pointers.
- Then `git -C /Users/federico/Developer/collections-app pull --rebase && git -C /Users/federico/Developer/collections-app push`.
- Commit at natural points (task started, PR opened, decision recorded), not on every edit.
- Submodule pointer bumps are the orchestrator's job, only to commits already on the service repo's `main`.

Several sessions share one working copy of these files, so edit safely:
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
