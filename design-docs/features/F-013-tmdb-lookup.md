# F-013 — TMDB lookup and automatic images (pool item 4)

Status: **approved** (2026-10-16, answers by the user)    Release: backend 1.5.0, web 2.4.0    Roadmap: ROADMAP.md §7 item 4
Repos: backend | web | parent    Contract: `api-v0.9.0`

## Why
Filling a movie by hand is slow. The user types a title, in any language and not exactly; the app finds the right film or show and fills in the rest, including the poster.

## Decisions (with the user, 2026-10-16)
- **Server-side key.** The TMDB API key lives in `deploy/server/.env` (`TMDB_API_KEY`), read by the backend only. It is never committed and never reaches the browser. The user provides it.
- **Movies and TV shows only.** Books go to Future.
- **Smart match, no exact title needed.** TMDB search matches original, translated and alternative titles, so "2001 odissea nello spazio" finds "2001: A Space Odyssey". The flow:
  - While typing the title of a new movie/TV item, a dropdown suggests matches (debounced, localized by the search text, shown in the metadata language), so a partial localized title like "2001 odissea nello" already suggests the English title.
  - Choosing one, or pressing Enter, fills the item. If the user commits the title **without** choosing, the backend takes the **first result** automatically.
  - The user can always change it afterwards ("Wrong match?" action on the item) or turn the lookup off for that item. A user-entered value is **never silently overwritten**: lookup only fills empty fields, except when the user explicitly asks to re-match or refresh.
- **Filled automatically:** title (in the metadata language), release or first-air year, runtime or seasons, IMDb URL, streaming platforms for the workspace's streaming country, and the **poster stored as the item's image** (downloaded server-side through the normal image pipeline, EXIF stripped, only if the item has no image).
- **Director (movies only).** A new `director` text field on the movie kind, filled from TMDB credits when available (several directors joined with ", "), editable by hand, pinnable, **sortable and filterable**: it joins the sort modes of movie lists and the list filter box also matches it.
- **Metadata language:** a Settings choice, default English (so the example resolves to the English title); it is passed to TMDB as `language`.
- **Attribution** in Settings → About, as TMDB requires: its logo and "This product uses the TMDB API but is not endorsed or certified by TMDB." The About also links the GitHub repo (`https://github.com/0xfederama/collections-app`, private for now) and the author's profile (`https://github.com/0xfederama`).
- No IMDb scraping. Rate limits are respected (the backend caches search results and throttles).

## User stories
### Backend
- **F013-B1 · TMDB client.** Server-side client with the key from config, timeouts, a rate-limit guard and a short cache. Starts by checking TMDB's current terms (attribution, caching limits, image use) and flags anything that conflicts with the decisions above. Missing key means lookup is disabled and says so; the app keeps working.
- **F013-B2 · Suggestions.** An endpoint returning ranked matches for a text and kind (movie or tv_show): TMDB id, localized and original title, year, poster thumbnail URL, a short overview. Works with non-exact and non-English text.
- **F013-B3 · Fill an item.** Create-with-lookup (title only, takes the first result) and match-by-id for a chosen suggestion, plus **re-match** and **refresh** on an existing item. Fills only empty fields unless re-match or refresh is asked; stores the TMDB id in the item's metadata so a refresh needs no search. Streaming availability uses the workspace streaming country. Poster stored through the existing image pipeline.
- **F013-B4 · Director.** `director` field on movie (validator, sort mode, filter match, pinnable keys), filled from credits. Migration only if needed.
- **F013-B5 · Settings.** Metadata language; lookup availability exposed to the client.
- **Contract:** `api-v0.9.0`. `make test-backup` if there is a migration; `make audit` before the `v1.5.0` tag (D-084).

### Web
- **F013-W1 · Title lookup on create.** The movie/TV title field shows the suggestions dropdown (poster, title, year); keyboard: arrows, Enter picks, Esc closes. Enter without a pick, or committing the title, uses the first result. Works in the draft item side page and in Quick add. Lookup disabled state shows nothing odd.
- **F013-W2 · Filled item.** The item shows the filled fields and poster; "Wrong match?", "Re-match" and "Refresh from TMDB" in the item's actions; clear feedback while it loads and when nothing matches (the item is kept as typed).
- **F013-W3 · Director.** Shown, editable, pinnable, in the sort menu and found by the list filter on movie lists.
- **F013-W4 · Settings.** Metadata language choice; About section with the TMDB attribution (logo + notice), the repo link and the author link.
- **Release:** web 2.4.0; update the affected e2e specs against a backend with a stubbed TMDB (no network in tests); `npm run audit` before the `v2.4.0` tag.

### Parent (top-level orchestrator)
- `TMDB_API_KEY` in `deploy/server/.env.example` and the compose wiring; `deploy/README.md` and the backend README say where to get and put the key. The key itself is never committed.

## Contract impact
`api-v0.9.0` (additive: suggestions, lookup/re-match/refresh, `director`, settings). Web pins to it after the backend tags.

## Constraints
- Lean workflow D-079/D-081 with the AI-agnostic tiers of D-087; one PR per repo; the orchestrator runs the gate once at the end (`make test-backup` if a migration, `npm run e2e` on a fresh `./deploy/test`); squash merge yourself.
- Tests never call the real TMDB: use a fake server or recorded fixtures.
- Frosted Gallery and D-083 stay.

## Out of scope
Books and other kinds, another provider, IMDb data, the Compare/AI concept, offline cache of posters beyond the stored image.

## Repo breakdown (filled by the repo orchestrators)

## Log
- 2026-10-16: written from the user's answers.
