# CLAUDE.md — collections-app (parent repo)

Parent repo with two git submodules: `backend/` (collections-app-backend) and `frontend-web/` (collections-app-frontend-web).
Design docs live in `design-docs/` (read `design-docs/README.md` and `AGENT_WORKFLOW.md` first; reference by absolute path
`/Users/federico/Developer/collections-app/design-docs/`). Layout and submodule rules: design-docs/README.md, D-043.

- Service code changes go in the submodule's own repo/branch/PR, never in the parent.
- Parent commits: docs, `deploy/` (environments: `./deploy/dev|test|prod`, see deploy/README.md), README, and submodule
  pointer bumps (only to commits already pushed).
- To run the app for a check, use `./deploy/test up -d --fresh` (ports 5183/8090), never the user's dev data.
