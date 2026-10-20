# F-020 — Web architecture refactor

Status: **planned** (2026-10-21, from the user's request; defaults below to confirm in the first report)    Release: web 2.18.0 (see F020-Q1)    Roadmap: ROADMAP.md §6
Repos: web    Contract: adopts `api-v1.0.0` (F-019)    Companion: [F-019](F-019-backend-architecture.md) (backend)

## Why
The UI is where the app wants to be; the code behind it should match. The web is about 25k lines, with several very large files (the Types & fields pane is about 880 lines, Settings form 510, Quick add 450, the inline field 450, the draft model 490, the sortable primitives 320, list and items views 320 each), a hand-grown mock layer and dev gallery, and URL building for stores and streaming done by the backend. Same bar as the backend: a reader should say "this is clean". **The UI must not change**: same look, same behaviour, same e2e results.

## Principles (the acceptance bar)
1. **Feature slices with a public face.** Each feature folder exposes only what others may use through its `index.ts`; its internals are `api/` (queries, mutations, key factories), `model/` (pure logic, types, validators), `ui/` (components), `hooks/`. Features do not import each other's internals; `components/ui` (the design system) imports nothing from features. This is **enforced by lint** (import restrictions or an import-boundary plugin), not by convention.
2. **Pure logic apart from React.** Anything that can be a plain function (formatting, link building, draft/validation, ordering, pinned-field rules) lives in `model/` with table-driven unit tests; components are thin.
3. **Small files.** No component or module over about 250 lines without a written reason; the large ones above are split along their real seams (for example Types & fields into a type list, a type editor, a field editor, dialogs).
4. **One data layer.** A single API client module, per-feature query-key factories, consistent mutation hooks (optimistic updates and If-Match handled in one place), and one mapping from problem+json errors to what the UI shows.
5. **Strict and boring TypeScript.** `strict` plus `noUncheckedIndexedAccess` and similar flags that are practical; no `any`, no non-null assertions without a comment; ESLint flat config with the boundary rules above; Prettier as now.
6. **Dev code stays out of production.** The `/dev/ui` gallery and any mocks are dev-only (dynamic import behind a dev flag) and are removed if the real-backend e2e and small local test fixtures make them unnecessary. Generated artefacts (`src/generated`) are minimal; if the MSW examples file is only a mock source, it goes.
7. **Behaviour is preserved.** All unit tests that still make sense are kept (moved with their code), the 50 e2e specs run unchanged, and both themes keep zero serious or critical axe findings.

## What moves from the backend to the web
Link building is a pure function of data the web already has, so it belongs here: **Google, IMDb, Reddit, Goodreads, Open Library, Amazon (country-aware), Bookshop, Apple Books, Kobo and the streaming search URL per platform and country** become one `links` feature (table-driven, fully unit-tested, one place to fix a URL). The API keeps returning the data (ISBN, title, streaming platforms and country, TMDB's own `streaming.link`). Candidates the orchestrator should also check and report (move only if clearly better): derived display values such as default icon choice and colour tokens, and any formatting the backend does for display.

## User stories
- **F020-W1 · Links in the web.** Create `features/links` with the builders above; switch every use (item detail link tiles, row store and streaming tiles, quick add) to them; the backend fields `store_links` and `platform_links` are no longer read. Needs no new contract and can start immediately; it unblocks the link removal in F-019-B4/B5.
- **F020-W2 · Conventions and enforcement.** Write the structure rules into `frontend-web/docs` and `CLAUDE.md`; add the lint rules (boundaries, max lines as a warning, strict TS flags); fix the violations or list them as work items.
- **F020-W3 · Split the big files.** Along the real seams, with their tests, one PR per area: settings (Types & fields, Settings form), items (inline field, editors, draft model), lists and tree (list view, items view, tree dialogs, sortable), quick add.
- **F020-W4 · Data layer.** One client module, query-key factories, mutation helpers, error mapping; remove ad-hoc `fetch` and duplicated invalidation.
- **F020-W5 · Dev tooling and generated code.** Gate the dev gallery and mocks out of the production bundle (verify with the build output), drop what is unused, keep the contract sync flow (`api:sync`, `api:check`).
- **F020-W6 · Adopt `api-v1.0.0`.** After the backend tags it: sync the contract, adapt names, run the full gate and e2e; remove leftovers of the old contract; final clean-up pass by a fresh reviewer session (`/code-review` at high effort and `/simplify`).
- **Release:** web 2.18.0; `npm run check`, `npm run e2e` on a fresh `./deploy/test`, `npm run audit` before the tag.

## PR plan
W1, W2, W3 (several PRs), W4, W5 before the contract; W6 together with the backend's contract-changing PR. Each PR is squash-merged by the orchestrator, leaves the app working and the e2e green. Do not mix refactors with feature changes.

## Constraints
- Lean workflow D-079/D-081, AI-agnostic tiers (D-087): complex worker tier for W3 and W4, simple for mechanical moves, the links tables and docs.
- Frosted Gallery and D-083 stay untouched; the word is "type" (D-094).
- No new runtime dependency without a line in the PR saying why; a boundary-lint plugin is the expected exception if the built-in rules are not enough.

## Out of scope
New features, visual design, backend work, accounts.

## Open questions
| ID | Question | Default |
|---|---|---|
| F020-Q1 | Version of the release | web 2.18.0 |
| F020-Q2 | Keep the MSW mock layer | Remove if the e2e on the real backend and small local fixtures cover its uses |
| F020-Q3 | Boundary lint tool | ESLint `no-restricted-imports` first, a plugin only if it is not enough |

## Repo breakdown (filled by the repo orchestrator)

## Log
- 2026-10-21: planned from the user's request.
