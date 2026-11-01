# F-022 — Fewer customizations, my streaming services, icon gaps

Status: brief (2026-11-01). Repos: backend, frontend-web. Workflow v2 lean (one PR per repo, one gate).

## Decisions (user, 2026-11-01)

| # | Decision |
| --- | --- |
| 1 | **Custom item types (kinds) are removed.** Only the five built-in types remain (D-105). Custom fields stay. No backward compatibility (prod unused): edit the baseline migration, no data migration. |
| 2 | **Pinned fields are no longer customizable.** Each built-in type has fixed pinned fields defined in code; the per-list/per-kind pin setting, its API and its UI go away. |
| 3 | **My streaming services:** a Settings selector of the services the user owns. Only those are shown (item streaming rows, availability); the rest are hidden. Empty selection = show all. |
| 4 | **Icons:** Apple TV Store reuses the Apple TV+ icon; Amazon Video reuses Prime Video; add Chili. Every icon gets a white tile background when it has none (D-109 `tile`). |

## Backend stories
- B1: drop custom kinds (endpoints, service, repository, tables in the baseline migration, OpenAPI). Built-in kinds stay locked data.
- B2: drop pinned-field configuration; expose the fixed pins per built-in type (or drop them from the contract if the web owns them; repo orchestrator decides, contract stays minimal).
- B3: store the owned streaming services as an app setting (GET/PUT, list of provider keys from the existing provider list). New contract minor version.

## Web stories
- W1: remove the custom-type UI (Settings → Kinds & fields keeps custom fields only), routes, slices, tests.
- W2: remove pin customization UI; rows show the fixed pins per type.
- W3: Settings selector for owned streaming services; hide unselected services everywhere streaming is shown; empty = all.
- W4: icon registry: map Apple TV Store → Apple TV+, Amazon Video → Prime Video, add Chili (official SVG, vendored); white tile for every icon lacking a background.

## Log
- 2026-11-01: brief written.
