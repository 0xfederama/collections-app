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
- **F020-W6 · Adopt `api-v1.0.0`.** After the backend tags it: sync the contract, adapt names, run the full gate and e2e; remove leftovers of the old contract; final clean-up pass by a fresh reviewer session (`/code-review` at medium effort and `/simplify`).
- **Release:** web 2.18.0; `npm run check`, `npm run e2e` on a fresh `./deploy/test`, `npm run audit` before the tag.

## PR plan
W1, W2, W3 (several PRs), W4, W5 before the contract; W6 together with the backend's contract-changing PR. Each PR is squash-merged by the orchestrator, leaves the app working and the e2e green. Do not mix refactors with feature changes.


## Execution model (user decision 2026-10-21, overrides the D-087 tier choice for this refactor)
- **All code is written by simple-tier workers (Haiku 5.5 or GPT 6 Luna, medium)**, even for the complex tasks. The orchestrator tier plans, reviews and runs the gates. Escalate a task to the complex tier only after a simple worker has failed it twice, and say so in the Repo breakdown.
- **So the plan must be expanded by the repo orchestrator into task specs.** This brief fixes the design and the order; it does not say which files change. Before dispatching, the orchestrator writes one spec per task (kept in the Repo breakdown or a `tasks/` note in the PR): the files to create, change or delete; the target type and function signatures; the exact tests that must pass (and which existing tests must stay green); what the worker must not touch; the layer rules to respect. A task is small enough to be reviewed as one diff (about 300 changed lines at most, one seam at a time).
- **Characterization first.** Before a seam is rebuilt, a task adds tests that pin its current behaviour (component, hook or e2e level). Workers then rebuild until those tests pass unchanged. This is what makes a small model safe on a big refactor.
- **Machine checks beat review.** The layer and import rules are enforced by lint or a test (web boundary lint (ESLint)), so a worker cannot quietly break the architecture; the orchestrator reviews the FLAGS and the diff of the risky parts only.

## Additional scope (added 2026-10-21)
- **Unused code and dependencies:** `knip` (or equivalent) in the final pass to remove unused files, exports and packages.
- **Accessibility lint:** `eslint-plugin-jsx-a11y` on top of the axe e2e checks.
- **Lazy routes and a bundle report:** route-level code splitting where it helps, and the build prints the bundle sizes (no hard budget, D-034). Evaluate the React Compiler and remove hand-written memoisation only if the compiler is adopted and the e2e stay green.
- **Docs that match:** `frontend-web/docs` and the README describe the new structure; `CLAUDE.md` / `AGENTS.md` keep one source of truth.

## Constraints
- Lean workflow D-079/D-081, AI-agnostic tiers (D-087): see Execution model: simple-tier workers for all code (D-107).
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

## Repo breakdown (filled by the repo orchestrator, 2026-10-20)

Execution: every task below is written by a simple-tier `worker` (Haiku 5.5, medium); no task has been escalated (escalation after two failed attempts is recorded here when it happens). Workers do not run the full gate; the orchestrator runs `npm run check` once per PR and `npm run e2e` (fresh `./deploy/test`) for PRs that touch behaviour. Each PR: worktree in `../frontend-web-<tag>`, squash merge, branch and worktree deleted. Common do-not-touch for every task: `src/generated/`, `api/`, `e2e/` (unless the task says so), `CLAUDE.md`, design docs; no new dependency; no visual or behaviour change. Common verification per task: its targeted vitest files, `npm run typecheck`, `npx eslint .` (0 errors), `npm run knip`, prettier on touched files.

### W1 · `links` feature: DONE ([web#81](https://github.com/0xfederama/collections-app-frontend-web/pull/81), squash `b98ef1b`)
- W1.1 `features/links/model/stores.ts` (+test, 61 cases ported from the backend's Go table): `amazonDomain(country)`, `storeLink(provider, {isbn,title,country}) -> string|null`, Go-compatible `queryEscape`.
- W1.2 `features/links/model/streaming.ts` (+test, 43 cases): `normalizePlatform`, `streamingSearchLink(platform, title) -> string|null`.
- W1.3 `git mv` of `items/links.ts` and its test to `links/model/external.*`, public face `links/index.ts`; importers updated.
- W1.4 `FieldBlock` (item stores) and `ItemEntry` (row store and streaming tiles) call the builders (country from Settings); `store_links` / `platform_links` are no longer read (tests assert that hostile values in them are ignored).
- Gate: `npm run check`, e2e 50/50 (6 setup POSTs failed once on the cold stack, passed on rerun). Open for the backend (F-019-B4/B5): the API can drop `store_links` and `platform_links`.

### W2 · conventions and enforcement: DONE ([web#82](https://github.com/0xfederama/collections-app-frontend-web/pull/82), squash `e090149`)
- W2.1 tsconfig `noImplicitOverride` + `noImplicitReturns` (`exactOptionalPropertyTypes` deliberately off: 76 errors against the generated types); ESLint `jsx-a11y` (npm override because its last release peers ESLint <= 9), `no-explicit-any`, `no-non-null-assertion` in production code, `max-lines` warning at 250; 25 a11y sites carry a written disable reason, none changed.
- W2.2 `eslint.boundaries.js` (`no-restricted-imports`, rules A/B/C) with `eslint.boundaries.baseline.js` (73 legacy files, only shrinks) and `src/boundaries.test.ts`.
- W2.3 `knip` (`knip.json`, part of `npm run check`); about 50 unused exports and some dead code removed.
- W2.4 `docs/architecture.md`; `AGENTS.md` is a symlink to `CLAUDE.md`.
- Follow-up found: `StoreChoices` error text is not linked to its trigger (`aria-describedby`); a real a11y gap, not in this refactor (behaviour change).

### W3 · feature faces and splitting the big files: DONE (web#83 `1a9a89d`, #84 `2e0b8a7`, #85 `78a6ad4`, #86 `0bb6749`, #87 `3417f95`)
- **W3-0 feature faces** (#83): explicit-export `index.ts` for every feature, plus `testing.ts` (test kits) and `screens.ts` (heavy route-level screens, imported by `src/routes`; `stores/screens` is the one documented exception for features). Every outside import goes through them; the legacy baseline of 73 files was emptied, so the boundary rules A/B/C apply everywhere. Route chunks and the main bundle did not grow (index 245 -> 240 kB). Tasks F1 tree, F2 items, F3 lists+settings (+F3b `screens.ts` correction of a worker's per-pane `lazy()` that changed loading behaviour), F4 the rest.
- **D quickadd** (#84): D1 pure `model.ts` (validate, list resolution), D2 `describeCreateFailure`, D3 `ListPicker`, `OptionalFields`, `QuickAddFooter` (454 -> 264 lines).
- **B items** (#85): B1 `form/draft.ts` 487 -> 113 (`price`, `validate`, `patch`, `serverErrors`, `dump`), B2 `InlineField` 446 -> 99 (`controls`, `FieldEditor`, `FieldEditorBanner`), B3 `editors` 315 -> 136, B4 `DescriptionField`/`ImageSection`.
- **C lists and tree** (#86): C1 `ItemEntry` (`ItemPinned`, `ItemControls`), C2 `ItemsView` (`ItemsSkeleton`, `ItemRows`), C3 `listParams.ts` + `useDebouncedFilter`, C4 `ListDescription` view/editor, C5 `useTreeDialogs` (`treeLookup`, `Vanished`, `listFolderMemory`, `createTreeMoves`).
- **A settings** (#87): A1 characterization tests (10) first, A2 `types/model.ts`, A3 row components, A4 `CreateTypeDialog`/`DeleteTypeDialog`/`ChangeListsDialog`/`DeleteFieldDialog`/`OperationBanner`, A5 `FieldsSection`/`DefaultsSection`/`TypeHeader`/`TypeList` (pane 878 -> 248), A6 `SettingsForm` 514 -> 83 (`useSettingsForm` verbatim move with one documented max-lines disable, `useLeaveGuard`, `classifySaveFailure`, banners/fields components).
- `components/ui/sortable.tsx` keeps one file with a written `max-lines` reason (single @dnd-kit adapter, D-061).

### W4 · data layer: DONE (web#89, squash `c2a97c4`)
`src/data/keys.ts` (every query-key factory, values unchanged) and `src/data/invalidate.ts` (`invalidateContent`, new `invalidateItemWrite`); `src/data` imports no feature (lint rule A + tests). `src/lib/api/failure.ts` `failureKind` is the one HTTP-failure mapping used by the tree, trash, items and settings classifiers (wording stays in the feature). Findings: the client was already single (`lib/api`, raw `fetch` only in the XHR upload and the test fake), so no client change.

### W5 · dev tooling and generated code: DONE (web#88, squash `6079100`)
Dev code was already gated at build time (`import.meta.env.DEV` for `/dev/ui`, `VITE_API_MOCKS` for the worker) and absent from `dist`; `scripts/dist-check.mjs` (in `npm run check`) now fails if it ever reaches `dist` and prints the chunk sizes (no budget). `DevUiRoute` 505 -> 72 lines (`src/dev/sections/*`), `devTree` split into a folder. F020-Q2: MSW kept (about 100 test files use it; the dev fakes also give the backend-less mode). React Compiler evaluated 2026-10-20 and NOT adopted (only about 24 manual memoisation lines; needs `@rolldown/plugin-babel` + `babel-plugin-react-compiler` + `@babel/core`; dnd-kit 0.5.0 untested; trigger: measured re-render cost). `src/generated/schema.d.ts` is types only (erased from the bundle) and `examples.ts` is the test-handler source, so both stay.

### Reviewer passes: DONE
- `/code-review` medium over `8847410..HEAD`: 9 findings, 7 fixed in [web#90](https://github.com/0xfederama/collections-app-frontend-web/pull/90) (`ff14d62`: dist-check hash false positive, `keepFormError` flag, field drafts across loading views, `createTreeMoves`, `screens` routes-only lint, lib/component tests import mocks directly, sortable primitive tests back in `components/ui`), 2 skipped on purpose (the change-lists dropdown offers the type being deleted: pre-existing, a behaviour change; dynamic `import()` of four lazy components is not covered by `no-restricted-imports`: documented).
- `/simplify` ([web#91](https://github.com/0xfederama/collections-app-frontend-web/pull/91), `a521b4f`): shared `focusRing`, one `queryEscape`, `errorMessage`, `parseStringArray`, shared `typesTestKit`.

### Follow-ups found (candidates for a next feature, not done here, no behaviour change intended)
1. A lower layer so features stop importing each other in cycles: `ListIconMark`/`ListIconPicker`/`iconModel` (lists, used by tree, settings, items), the type-definition helpers (`items/types`) and `useTypes`/`useSettings` (settings), and the tree read model (`ListGate`, `useTreeIndex`, tree types). Today the barrels hide lists<->tree<->items<->settings cycles.
2. The target folder layout (`api/ model/ ui/ hooks/`) only exists in `links`; `lists` and `tree` have about 40 flat files each. A lint rule banning `react` imports in `model/**` would make "pure logic" checkable.
3. A shared `Banner` primitive (about 12 near-identical banner markups) and one `Failure` type for the item/settings/description editors.
4. Move `StoreChoices` logos behind a lazy boundary so `stores/screens` (the only carve-out in the boundary rules) can go.
5. Bugs found, not fixed (behaviour): the Types pane change-lists dropdown offers the type being deleted; `StoreChoices` error text is not linked to its trigger (`aria-describedby`).

### W6 adopt `api-v1.0.0`: DONE (web#92, main `08add56`, 2026-10-31). Contract synced; the spec has no examples, so the MSW fixtures are hand-owned in `src/mocks/fixtures.ts`; enums are web-owned unions; nullable slices are normalised once in each `queryFn`. Gate green (1661 tests), e2e 51/51 on a fresh `./deploy/test`, `npm run audit` 0 (after `npm audit fix` for a transitive `undici` advisory). Reviews: /code-review 6 findings (2 fixed, 4 skipped), /simplify. **Backend asks:** (1) `Item.price`, `ItemSummary.price`, `ItemSummary.image` are typed non-null but sent as `null` (add `nullable:"true"`); the web widens them until fixed. (2) Say what `former_path: null` means in Trash (web reads it as top level).

### Release web 2.18.0: tagged `v2.18.0` on `08add56` (2026-10-31).

**Note on e2e (found during this feature):** `./deploy/test` runs a Vite dev server on the MAIN checkout of `frontend-web/` (compose mounts `../../frontend-web`), not on a worktree. To e2e a branch, check it out (detached) in the main checkout first, or the run tests `main`.

## Log
- 2026-10-21: planned from the user's request.
- 2026-10-20: W1 and W2 merged (web#81, web#82); W3 in progress, see the breakdown.
- 2026-10-20: W3, W4, W5 merged (web#83-#89), reviewer passes done (web#90, #91). W6 and the 2.18.0 tag wait for the backend tag `api-v1.0.0`.
