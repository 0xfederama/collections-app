# Collections App

Self-hosted app to organise collections (folders, lists, items with images). This is the **parent repo**: it ties the
two service repos together as git submodules and holds the design docs and the whole-app local setup.

| Path | What | Repo |
|---|---|---|
| `backend/` | Go API + Postgres + canonical OpenAPI contract | [collections-app-backend](https://github.com/0xfederama/collections-app-backend) (submodule) |
| `frontend-web/` | React + TypeScript + Vite web app | [collections-app-frontend-web](https://github.com/0xfederama/collections-app-frontend-web) (submodule) |
| `design-docs/` | Product, architecture, API, data model, decisions, status, agent workflow | this repo |
| `compose.yaml` | Whole-app local dev (db + migrate + api + Vite dev server) | this repo |

## Quick start

```bash
git clone --recurse-submodules https://github.com/0xfederama/collections-app.git
cd collections-app
cp backend/.env.example backend/.env      # set POSTGRES_PASSWORD (URL-safe characters only)
docker compose up --build
```

- Web: http://localhost:5173 (Vite proxies `/api` to the backend)
- API: http://localhost:8080 (`/healthz`, `/readyz`)

Already cloned without `--recurse-submodules`: `git submodule update --init --recursive`.

## Working with submodules

1. Work and push inside the submodule (`cd backend`, `git switch -c ...`, commit, open a PR in that repo).
2. After the PR merges, bump the pointer in the parent: `git -C backend switch main && git -C backend pull`, then
   `git add backend && git commit -m "chore: bump backend"`.
3. Update all submodules to their latest remote `main`: `git submodule update --remote --merge`.

Submodules check out a detached commit by default, so run `git switch <branch>` inside one before editing.

## Docs

Start at [design-docs/README.md](design-docs/README.md) (reading order, precedence, session rules) and
[design-docs/STATUS.md](design-docs/STATUS.md) (current progress).
