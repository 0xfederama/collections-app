# Collection App — Design Docs

Canonical design package for the Collection App. Every agent session working on
`collections-app-backend` or `collections-app-frontend-web` must treat these documents as the source of truth.

**Absolute location:** `/Users/federico/Developer/collections-app/design-docs/`
(always reference it by absolute path — sessions may run inside git worktrees where `../` resolves elsewhere).

## Local layout

```text
/Users/federico/Developer/collections-app/
├── README.md, CLAUDE.md, .gitignore   ← parent repo files
├── deploy/                        ← environments: ./deploy/dev, ./deploy/test (local), ./deploy/prod (home server), D-073
├── design-docs/                   ← this folder: living plan, decisions, status, templates (tracked in the PARENT repo)
│   └── collection_app_detailed_conversation_archive.md  ← original source conversation (historical)
├── backend/                       ← git submodule → github.com/0xfederama/collections-app-backend
└── frontend-web/                  ← git submodule → github.com/0xfederama/collections-app-frontend-web
```

The parent repo is `github.com/0xfederama/collections-app` (D-043). **Local folders are short (`backend`, `frontend-web`);
GitHub repo names keep the `collections-app-` prefix.** Wherever these docs say `collections-app-backend` or
`collections-app-frontend-web` they mean the repo/remote; the local folder is `backend/` or `frontend-web/`.

### Working with the submodules (rules for every session)
- **Two-step commits:** commit and push inside the submodule first (its own branch + PR), then, in the parent, commit the
  updated submodule pointer (`git add backend && git commit`). Never commit a pointer to an unpushed commit.
- Design-doc changes are committed in the **parent** repo, not in a submodule. STATUS.md etc. are parent files.
- Submodules start on a detached HEAD; `git switch <branch>` inside one before working. Service worktrees are created
  from inside the submodule (`backend/` or `frontend-web/`).
- Bumping the pointer after a service PR merges is a small parent commit (`chore: bump backend to <sha>`); the
  orchestrator does it, workers do not.
- Fresh machine: `git clone --recurse-submodules https://github.com/0xfederama/collections-app.git`
  (or `git submodule update --init --recursive`).
- Service `CLAUDE.md` files and PR templates stay in each service repo; their absolute design-docs path is unchanged.

## Reading order

| # | Document | Read when |
|---|---|---|
| 1 | [AGENT_WORKFLOW.md](AGENT_WORKFLOW.md) | **Every session, first.** Git/PR rules, model dispatch policy, docs upkeep |
| 2 | [ORCHESTRATOR_BRIEF.md](ORCHESTRATOR_BRIEF.md) | Every orchestrator session; scope rules, roles, checkpoints |
| 3 | [DECISIONS.md](DECISIONS.md) | Before deviating from anything; decisions + open questions |
| 3b | [STATUS.md](STATUS.md) | Every session: who is doing what, PRs, blockers. Update it as you work |
| 4 | [PRODUCT.md](PRODUCT.md) | Feature behavior, MVP scope, roadmap |
| 5 | [ARCHITECTURE.md](ARCHITECTURE.md) | Stack, repo layouts, boundaries, extension points |
| 6 | [DATA_MODEL.md](DATA_MODEL.md) | Backend: schema, constraints, trash, versions, images |
| 7 | [API.md](API.md) | Both: endpoints, ETags, errors, pagination |
| 8 | [UI_SPEC.md](UI_SPEC.md) | Frontend: screens, states, design system |
| 9 | [ACCEPTANCE_TESTS.md](ACCEPTANCE_TESTS.md) | Writing tests; definition of done |
| 10 | [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md) | Picking up work; milestones, task IDs, dependencies |
| 11 | [BACKUP_AND_DEPLOYMENT.md](BACKUP_AND_DEPLOYMENT.md) | Compose, env vars, backup/restore, deployment |

`handoffs/` holds per-task briefs written by repo orchestrators for worker sessions (AGENT_WORKFLOW §1b).
`templates/` contains files to copy into the repos at bootstrap (CLAUDE.md, subagent definitions, PR template).

## Precedence when documents disagree

1. `DECISIONS.md` (newest entry wins)
2. `API.md` / `DATA_MODEL.md` (contracts)
3. Everything else
4. The original conversation archive (historical only — several of its points are superseded, see DECISIONS.md)

Once implemented, `backend/api/openapi.yaml` becomes the authoritative API contract; `API.md` then
describes intent and conventions, and any divergence must be resolved by updating one or the other in the same PR.

## Status

This folder is a **living planning workspace**: versioned in the parent `collections-app` repo (D-026 superseded by D-043), updated frequently by every session (AGENT_WORKFLOW §7).
It is not the services' documentation, which lives in each repo (`README.md`, `CLAUDE.md`, `docs/`).
Current progress is in [STATUS.md](STATUS.md).
