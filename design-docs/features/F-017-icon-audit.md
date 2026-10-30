# F-017 — Icon audit and fix (links, stores, streaming)

Status: **done** (2026-10-30, web#94, `v2.19.0`; see D-109)    Release: web 2.19.0    Roadmap: ROADMAP.md §6
Repos: web (no contract change)

## Why
Some of the icons shown for links, book stores and streaming services are missing, wrong or low quality (favicons resized to 96 px WebP, letter tiles where a logo exists), and they do not look like one family. The rule from the user: **every icon must be the correct one, and all must look the same size.**

## Decision rule (user, 2026-10-30)
Use an icon pack only if it has the correct, official symbols for **all** the icons we need; otherwise source each icon as an SVG.

**Checked on 2026-10-30 against Simple Icons 16.36.0 (CC0), the pack already used for Google and IMDb: it does NOT cover everything.**
- Present: Google, IMDb, Letterboxd, Reddit, Goodreads, YouTube, Netflix, Apple TV, Google Play, Paramount+, HBO Max, NOW, Sky, Audible.
- Missing: Amazon, Prime Video, Disney+, Kobo, Bookshop.org, Open Library, Apple Books, TIMvision, Mediaset Infinity, RaiPlay, Rakuten TV, Hulu.

So no single pack qualifies, and the answer is **per-icon SVGs**, taken from the best source available, in this order:
1. Simple Icons, when the icon exists and is the current official mark (CC0; the vendored path is kept as is).
2. The brand's own SVG: its press or brand kit, or the SVG logo/favicon the brand itself serves. Record the URL and date.
3. Another pack that has the official mark, checked one icon at a time (candidates to look at: svgl and gilbarbara/logos). Licence and trademark note recorded per icon.
4. Nothing official in SVG: a clean, large official raster, converted without redrawing it; if none exists, the neutral letter tile and a line in the report. **Never** redraw a logo by hand and never fetch icons at runtime. TMDB's provider logos are not used (runtime fetching and D-089 retention rules).

## Scope
The icons to cover are the ones the app can show today; the orchestrator first writes the **inventory** (a table in the PR and in `src/assets/services/README.md`), built from the code and from real data:
- Link tiles: Google, IMDb, Letterboxd, Reddit, Goodreads, Open Library, website (the neutral globe stays), and any other link kind in `features/links`.
- Book stores (`features/stores/providers.ts`): Amazon, Bookshop.org, Kobo, Apple Books, Open Library, Google Play Books if offered.
- Streaming services: the seven with files today (Netflix, Prime Video, Disney+, Apple TV+, YouTube, TIMvision, Infinity) plus the most common TMDB providers for the workspace's streaming countries (look at real provider names in a fresh test stack with the TMDB fixture and in the Settings country list; at least Paramount+, HBO Max / Max, NOW, Sky, RaiPlay, Rakuten TV, Hulu, Discovery+, MUBI, Google Play, YouTube).

## One system, one size
- **One registry** (key, label, aliases, asset, tile style) replaces the scattered maps in `ServiceIcon.tsx` and the hand-maintained `STREAMING_SERVICES`: the picker lists are **derived** from it, and a unit test fails when an entry has no asset or an asset has no entry.
- **All SVG**, one square `viewBox`, each mark optically centred and scaled to the **same fill ratio** inside the tile, never cropped. A registry field chooses the tile background per icon (light, dark or brand colour) so every mark stays readable in **both themes**.
- Unknown names keep the neutral letter tile.
- The existing tile size, radius and padding rules (F-009 W5) stay.

## User stories
- **F017-W1 · Inventory and sourcing.** Build the inventory, source every SVG by the order above, vendor them under `src/assets/services/` with a README table (file, source URL, licence/trademark note, date). Report any icon that ended up as a letter tile and why.
- **F017-W2 · Registry and tile.** Implement the registry, derive the picker lists from it, migrate `ServiceIcon`, the link tiles, store tiles and streaming tiles (rows, item detail, pickers, Settings), remove the old WebP favicons that are replaced.
- **F017-W3 · Visual proof.** A dev-only gallery page (reuse the existing dev gallery, which is not in the production bundle) shows every icon at the sizes used in the app (row tile, detail tile, picker) in light and dark; the orchestrator inspects screenshots of it and attaches them to the PR for the user. Unit tests cover the registry; the e2e axe checks stay at zero serious or critical.
- **Release:** web 2.19.0; `npm run check`, `npm run e2e` on a fresh `./deploy/test`, `npm run audit` before the tag.

## Contract impact
None.

## Constraints
- Lean workflow D-079/D-081, AI-agnostic tiers (D-087): the orchestrator tier does the sourcing, the licence notes and the visual inspection (judging "is this the right logo" is not for a small model); simple-tier workers do the wiring, the registry and the tests from the orchestrator's task specs.
- Frosted Gallery and D-083 stay. Trademarks are used for identification only; the README says so.

## Out of scope
New link or store providers, per-country availability, icon packs for the list icon picker (those are Lucide and emoji, F-012).

## Open questions
| ID | Question | Default |
|---|---|---|
| F017-Q1 | A brand with no usable official SVG | Official raster converted if clean, else letter tile and a report line |
| F017-Q2 | How many TMDB providers beyond the listed ones | The top providers for the countries in the Settings list, capped at about 25 |

## Repo breakdown (filled by the repo orchestrator)
| Task | Story | Branch | Result | PR |
|---|---|---|---|---|
| Inventory (34 icons: links, book stores, streaming) and sourcing in the brief's order, README table with source/licence/date | F017-W1 | `feature/F017-icon-audit` | done by the orchestrator; no icon ended as a letter tile | [web#94](https://github.com/0xfederama/collections-app-frontend-web/pull/94) |
| Registry `src/components/serviceIcons/` (key, label, aliases, asset, `tile`, `fit`), picker lists derived from it, `ServiceIcon` and every tile use migrated, old WebP favicons removed, registry test (file ↔ entry) | F017-W2 | same | done (simple-tier workers from task specs) | same |
| Dev gallery `/dev/ui#service-icons` (every icon at every size, light and dark), screenshots in the PR | F017-W3 | same | done | same |

Outcome: `npm run check` green, e2e green on a fresh stack after re-running 3 infrastructure flakes, `npm run audit` 0; streaming picker grew from 7 to 19 services.

### Deviations and caveats
- **Source fallback:** Wikimedia Commons was used as a fallback source for **Amazon** and **Apple Books** (the brand publishes no usable SVG); licence tags are recorded in the README. Hulu comes from svgl (wordmark); Open Library's own repository icon.
- **Brand rasters embedded as SVG wrappers:** where a brand only publishes a raster (Prime Video, Disney+, Infinity, RaiPlay, Kobo, Bookshop.org, Discovery+, Peacock, TIMvision, Rakuten TV) the official PNG is base64-embedded **unmodified** in a 100x100 SVG (no redrawing, no resampling). This is brief fallback 4 (a clean official raster, converted without redrawing); the registry stays all-SVG.
- **Low resolution:** TIMvision (96 px) and Rakuten TV (64 px) are the best icons those brands serve; the rest are sharp up to the largest tile (36 px).

## Log
- 2026-10-30: planned; coverage of Simple Icons checked (see the decision rule).
