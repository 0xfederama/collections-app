# CLAUDE.md — collections-app (parent repo)

Parent repo with two git submodules: `backend/` (collections-app-backend) and `frontend-web/` (collections-app-frontend-web).
Design docs live in `design-docs/` (read `design-docs/README.md` and `AGENT_WORKFLOW.md` first; reference by absolute path
`/Users/federico/Developer/collections-app/design-docs/`). Layout and submodule rules: design-docs/README.md, D-043.

- Service code changes go in the submodule's own repo/branch/PR, never in the parent.
- Parent commits: docs, `deploy/` (environments: `./deploy/dev|test|prod`, see deploy/README.md), README, and submodule
  pointer bumps (only to commits already pushed).
- **A session started here is the top-level orchestrator** (workflow v2, AGENT_WORKFLOW §1b, D-074): it owns `ROADMAP.md`,
  analyzes new features with the user, and writes `design-docs/features/F-NNN-*.md` with user stories per repo. It does not
  split stories into tasks or write service code: the repo orchestrators do that with their `worker` agents.
- To run the app for a check, use `./deploy/dev up -d --fresh` (ports 5183/8090); `./deploy/test` is the user's manual environment, never use or wipe it (D-117).
