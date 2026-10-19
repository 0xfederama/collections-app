# F-015 — Settings rework, "kind" becomes "type", lists without a type

Status: **done** (backend#34, #35; web#53, 2026-10-19)    Release: backend **2.0.0** and 2.0.1 (breaking API), web 2.6.0    Roadmap: ROADMAP.md §6
Repos: backend | web    Contract: `api-v0.11.0` (breaking)    Written after the fact by the top-level orchestrator, from the PRs; the work was requested by the user directly.

## Why
After F-014 the user changed three things at once:
- the word "kind" is confusing next to the new custom fields, so it becomes **type** everywhere
- the built-in "generic" type is gone: a list with no type is simply a list with no extra fields
- Settings needed a calmer layout

## What changed
### Backend (#34, #35)
- **Rename (breaking):** `/kinds` becomes `/types`; `kind` becomes `type` on lists, items and query params; `kind_mismatch` becomes `type_mismatch`; `kind_name` becomes `type_name`. Migration `000017` renames tables, columns, constraints, indexes, seed functions and the trigger (reversible, data-preserving). Package `items/kinds` becomes `items/types`.
- **No built-in generic type:** `lists.type` is nullable (migration `000018`). A list with no type has items with `type: null`, no fields, no price, and only the built-in sort modes. Create may omit the type; search `type_name` is nullable.
- **Price follows the definition (#35):** whether an item may have a price is read from the type definition's `allows_price`, not from a hard-coded list of built-in keys, so custom types can have a price.
- Tags: `api-v0.11.0`, `v2.0.0`, `v2.0.1`.

### Web (#53, web 2.6.0)
- Settings: a General pane (collection + appearance), no card behind the panes, a fixed top slightly above centre, a fixed Types & fields layout (full names, header stays), "New type" in its own layer.
- The new-list and change-type menus offer "No type" first, then a separator, then "+ New type" (opens Settings on the Types pane).
- Adopts `api-v0.11.0`; built-in types get their default pinned fields again from the backend.
- Gate: `npm run check` green (1234 tests), audit 0 vulnerabilities, e2e 34/34 on a fresh stack.

## Consequences for the docs
- The user-facing word is **type** from now on; older briefs (F-007 to F-014) keep "kind" as written then.
- Version policy: the API break made the backend **2.0.0**. D-080 had reserved backend 2.0 for accounts; see D-094.

## Log
- 2026-10-19: merged by the user's sessions; brief and D-094 written afterwards by the top-level orchestrator.
