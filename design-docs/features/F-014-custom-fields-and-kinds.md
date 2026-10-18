# F-014 — Custom fields and custom kinds (pool item 5)

Status: **approved** (2026-10-18, answers by the user)    Release: backend 1.6.0, web 2.5.0    Roadmap: ROADMAP.md §7 item 5
Repos: backend | web    Contract: `api-v0.10.0`

## Why
The kinds (movie, TV show, motorcycle, car, camera, generic) and their fields are fixed in code, in both repos. The user wants to add fields (e.g. a *Rating* on movies) and to create their own kinds (e.g. *Board game*), without a release.

## Decisions (with the user, 2026-10-18)
- **By kind, not by list.** Fields belong to a kind and every list of that kind shows them.
- **Defined in Settings,** in a new pane (e.g. "Kinds & fields") so Settings does not grow into one long page. The orchestrator checks the Settings layout from the latest web changes and splits it into panes if it is not already.
- **Field types, first round:** text, number, date, yes/no, link. No pick-one choice yet (Future).
- **All three behaviours** for every field, built-in or custom: it can be **pinned** in rows, **sorted** on and **filtered** on.
- **Built-in kinds become data.** The six built-in kinds and all their current fields (including the TMDB-filled ones such as `director`, `streaming`, `imdb_url`) are seeded as definitions by a migration, with fixed keys. They are **locked**: a built-in kind cannot be deleted and its built-in fields cannot be removed or retyped. The user **can add custom fields to a built-in kind**. The user said director "should already be custom"; today it is a hard-coded movie field, so this story is what makes it data.
- **Custom kinds in the same round.** A custom kind has a name, an optional default icon (same picker rules as list icons), its fields, a default sort field, default pinned fields (at most two), and a switch "Allows a price" (price stays a single `amount` or a range, as in F-007). It starts like the generic kind (title, image, website, description) plus its own fields.
- **Never lose data.**
  - A kind cannot be deleted while any list uses it; the dialog says which lists, and offers to change them to another kind first.
  - Removing a custom field asks for confirmation that shows how many items have a value, then removes those values. Its pins and sort on it fall back to the kind's defaults.
  - Changing a list's kind keeps the existing rule: kind fields are cleared, with a warning (F007-Q3).
- TMDB keeps working by field key: only movie and TV built-ins are filled, as in F-013.

## User stories
### Backend
- **F014-B1 · Definitions.** Tables for kinds and their fields (workspace scoped, with `version` for optimistic concurrency); a migration that seeds the six built-in kinds and every existing field with the same keys, types and labels, so existing items and lists keep working unchanged. Field: key (stable, generated from the name, unique per kind), label, type, position. Idempotent, tested on a fixture with every built-in kind filled; `make test-backup`.
- **F014-B2 · Data-driven validation.** The per-kind validator registry (ARCHITECTURE §7) reads the definitions: item `metadata` is validated against the kind's fields by type (number is a finite number, date is ISO, link is an http(s) URL, yes/no is boolean, text is bounded). Unknown keys are rejected. Built-in special shapes (streaming, price) keep their dedicated validation.
- **F014-B3 · Management API.** Create, rename, reorder and delete custom kinds and custom fields; list all kinds with fields. Enforces the locks and the delete rules above; conflicts return clear errors. Field deletion strips the values from items in one transaction.
- **F014-B4 · Sort, filter, pin on any field.** Sort mode by any field of the list's kind (number numeric, date chronological, text case-insensitive, yes/no false first), empty values last. A filter on a field value (text contains, number min/max, date range, yes/no) combined with the existing title filter. `pinned_fields` and the default pinned fields accept any field key of the kind. Replaces the single `kind_key` sort of F-007.
- **F014-B5 · Custom kinds on lists.** Lists can use any kind key, built-in or custom; the list kind picker data comes from the definitions; search results show the kind name.
- **Contract:** `api-v0.10.0` (breaking: kind and field definitions replace the fixed enum). `make test-backup`; `make audit` before the `v1.6.0` tag (D-084).

### Web
- **F014-W1 · Settings panes.** Settings is split into panes (e.g. Appearance, Media, Kinds & fields, About) with a pane list; closing still saves as today. Works at 375 px and with the keyboard.
- **F014-W2 · Kinds & fields pane.** Lists the kinds, built-in ones marked and locked. Create a kind (name, icon, price switch, default sort, default pins); open a kind to add, rename, reorder (drag and keyboard) and delete fields, with the five types; built-in fields are shown read-only. Delete flows show the consequences described above.
- **F014-W3 · Items and lists use definitions.** The kind registry in `src/features/items/kinds/*.ts` is replaced by the definitions from the API, with a typed editor and display per field type. Item detail, "+ Add field", the list kind picker, pinned-field picker, sort menu and rows work for custom kinds and fields exactly as for built-ins.
- **F014-W4 · Filter by field.** The list filter box gains a field filter (a chip menu: pick a field, then a value or range matching its type), keyboard reachable, clearable, shown in the URL state like the sort.
- **Release:** web 2.5.0; update the affected e2e specs and add one that creates a kind and a field, adds an item, pins, sorts and filters on it; `npm run audit` before the `v2.5.0` tag. Both themes keep zero serious or critical axe findings.

## Contract impact
`api-v0.10.0`, breaking for kind handling. Web W3 and W4 pin to it; W1 and a read-only look of W2 can be prepared before.

## Constraints
- Lean workflow D-079/D-081 with the AI-agnostic tiers of D-087. This feature has a breaking migration and a registry rewrite, so the backend orchestrator uses the **complex worker tier** for B1 to B3 and the web orchestrator for W3. One PR per repo, gate once at the end (`make test-backup`, `npm run e2e` on a fresh `./deploy/test`), squash merge yourself.
- Keep Frosted Gallery and D-083. TMDB tests keep using the fixture (no real network).
- Anything editable uses a `version`. Lean (D-034): no field validation rules, defaults or required flags yet.

## Out of scope
Pick-one choice fields, per-list fields, required fields, field visibility rules, import/export of definitions, searching inside custom text values (Future: advanced search).

## Open questions
| ID | Question | Default |
|---|---|---|
| F014-Q1 | Rename a built-in kind's label? | No, locked |
| F014-Q2 | Hide a built-in field from a kind? | No, only pin or unpin it |

## Repo breakdown (filled by the repo orchestrators)

## Log
- 2026-10-18: written from the user's answers.
