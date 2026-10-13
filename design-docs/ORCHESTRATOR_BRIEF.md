# Orchestrator Brief

## 1. Goal

Build a polished, private collection app for two people (the owner and their partner) to organize
things they like, want, or are comparing: movies, motorcycles, purchases, and so on. It has one shared
workspace with nested folders, lists, and items. Items have rich fields, one image, and a Markdown
description with version history.

Deliverables are two GitHub repos, `collections-app-backend` and `collections-app-frontend-web`. Each is independently
buildable and testable, has CI, and is documented. Together they run as one app on a trusted
network.

## 2. Non-goals for MVP (hard scope fence)

Do **not** implement, scaffold, or add tables, endpoints, or UI for any of these:
- Accounts, auth, users, memberships (Phase 3)
- TMDB or any provider lookup or auto-refresh (Phase 2)
- Public API productization, rate limiting, API keys (Phase 4, to be re-discussed)
- AI/LLM anything (very distant future)
- Real-time collaboration, WebSockets, CRDTs, offline mode, auto-merge, diffs, rich-text editor
- Multiple images per item, items in multiple lists, custom workflows, Markdown/metadata search
- A mobile repo, a monorepo, microservices, Redis, queues, event sourcing, an ORM

Clean extension points (DATA_MODEL §9, ARCHITECTURE §7) are allowed. Speculative code is not.

## 3. Decision rules

1. Contracts first: `API.md` → `openapi.yaml` and `DATA_MODEL.md` → migrations are reviewed **before** parallel feature work.
2. If a design doc is ambiguous, choose the simplest option consistent with PRODUCT.md, record it in DECISIONS.md, and flag it in the PR. If it affects UX, data loss, security, or scope, **ask the user** instead.
3. Prefer boring, maintained, widely-used tools. Verify current stable versions via the `researcher` agent. Never take versions from memory.
4. Stop and ask before anything irreversible or outward-facing: repo visibility, publishing images or packages, branch-protection changes, deleting data.

## 4. Roles

One orchestrator session per repo is typical. A session may play several roles sequentially.

| Role | Owns | Repo |
|---|---|---|
| Orchestrator | Plan, task assignment, integration, DECISIONS.md, cross-repo contract sync, final review | both |
| Backend | Go service, migrations, sqlc queries, openapi.yaml, storage, tests | backend |
| Frontend | React app, design system, generated client usage, UI tests | web |
| Integration/QA/DevOps | Compose, CI, e2e (Playwright, lives in web repo), backup/restore scripts, deployment docs | both |
| Reviewer (optional) | Security/schema/API review of PRs against design docs; no feature additions | both |

Subagent usage follows AGENT_WORKFLOW §2.

## 5. Parallelization & dependencies

```text
M0 bootstrap (both repos, in parallel)
  └─► M1 contracts: openapi.yaml v0.1 + migrations v1   ◄── USER REVIEW GATE
        ├─► M2 backend core  ──────────┐
        ├─► M2 web shell + design system + mocked API (MSW from OpenAPI examples)
        │                               ▼
        ├─► M3 backend content/images/trash/search
        │                               ▼
        └─► M4 web features wired to real API
                                         ▼
                              M5 e2e, backup/restore, hardening ◄── USER ACCEPTANCE GATE
```

Foundational files with a single owner at a time, never edited concurrently by two PRs: `api/openapi.yaml`,
`db/migrations/*`, `src/components/ui/*` tokens, CI workflows, `CLAUDE.md`.

## 6. Integration checkpoints

| Checkpoint | Criteria |
|---|---|
| C0 after M0 | Both repos: `make check` / `npm run check` green on the skeleton (local, D-031), backend `docker compose up --build` healthy on 127.0.0.1, web `npm run dev` proxies `/api`, CLAUDE.md + agents + PR template present, versions researched and recorded |
| C1 after M1 | openapi.yaml lints; migrations up/down/up clean; user approved |
| C2 mid-M2/M4 | Web generates the client from pinned `api-v0.1.0`; basic tree/list/item flows hit the real API locally |
| C3 after M4 | All features usable end to end locally |
| C4 after M5 | Every ACCEPTANCE_TESTS.md item green; fresh-clone setup verified by an agent following only the READMEs |

## 7. Definition of done (MVP)

All of [ACCEPTANCE_TESTS.md](ACCEPTANCE_TESTS.md) pass in CI or via a documented manual check, both READMEs and CLAUDE.md files
are current, the backup/restore round-trip is verified, and nothing from §2 exists in either repo.

## 8. Decision logging

Every non-trivial choice made during implementation goes in `DECISIONS.md` as `D-NNN` with date, decision,
rationale, and alternatives. Superseded entries are marked, not deleted.
