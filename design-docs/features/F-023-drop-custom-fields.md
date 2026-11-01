# F-023 — Remove custom fields and the Types & fields settings

Status: brief (2026-11-01). Repos: backend, frontend-web. Workflow v2 lean.

## Decisions (user, 2026-11-01)
- The Settings "Types & fields" (Kinds & fields) section is removed, and custom fields with it. Items keep only the built-in fields of the five built-in types (D-105).
- The backend drops anything left of custom fields or kind/field definitions (endpoints, services, repositories, tables, filter/sort on custom keys, contract).
- The backend is treated as a project not yet started: no migrations, no compatibility. Edit the single baseline schema in place; dev and test databases are reset.

## Stories
- B1 backend: remove custom fields and field/kind definitions end to end; new major contract tag.
- W1 web: remove the Settings section, custom-field display/edit, filters and sorts on custom keys, and their tests and e2e specs.

## Log
- 2026-11-01: brief written.
- 2026-11-01: B1 done (backend#67, squash `9664fca`, backend 2.8.0, `api-v3.0.0`). Repo breakdown: one complex-tier worker (removal + registry), one PR. `make check`, `make smoke` on a fresh test stack, `make audit` clean.
- 2026-11-01: W1 done (web 2.22.0, D-115). F-023 complete.
