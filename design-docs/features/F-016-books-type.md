# F-016 — Books: a built-in type with automatic lookup

Status: **planned** (2026-10-19, from the user's request; defaults below to confirm)    Release: backend 2.1.0, web 2.7.0    Roadmap: ROADMAP.md §6
Repos: backend | web    Contract: `api-v0.12.0`

## Why
Movies and TV shows are filled from TMDB. Books should work the same way: write a title, the app finds the book and fills the rest, including the cover. Books also need a different row layout, because they have no streaming services.

## Decisions (with the user, 2026-10-19)
- **A new built-in type, "Book"** (locked like the other built-ins, seeded by a migration; custom fields can still be added). Default fields: **writer** (the author(s)) and **number of pages** (the equivalent of a movie's runtime). Also seeded: first publication year, ISBN, and the **"Where to get it"** field below. It allows a price.
- **Automatic lookup like TMDB:** type a title in any language, suggestions appear as you type, committing the title without choosing takes the first result, "Wrong match?", re-match and refresh exist as for movies. It fills the empty fields only and stores the **cover** as the item's image through the normal image pipeline. User-entered values are never silently overwritten.
- **Row layout for books** (the user's description): the **writer** sits with the title, the **page count** next to it, and the **"where to get it" icons on the far right**, where movies show streaming. This needs up to **three ordered pins** (see below).
- **"Where to get it" is the streaming equivalent.** There is no per-country availability API for books, so it is a field of store links, with the same tile style as streaming platforms, built from the ISBN or the title: for example Open Library (borrow), Bookshop.org, Amazon, Apple Books, Google Play Books, Kobo. The lookup fills the Open Library link when the book is found there; the other stores come from the stores the user selects in Settings (a multi-choice, like the streaming platforms), and can be changed per item. Icons for these providers are part of the icon work (F-017); until then they use the neutral letter tile.

## Defaults chosen (to confirm)
- **Source: Open Library** (open data, no key, covers included). Google Books is the fallback if a check with Italian and other non-English titles shows Open Library cannot find them. The backend orchestrator **verifies the terms and the multilingual quality first** and flags the result; the choice is not final until that report.
- **Three pins:** `pinned_fields` allows up to **3** keys. With 1 pin it sits beside the title; with 2, the first beside the title and the second at the far right (today's behaviour, so movies and TV are unchanged); with 3, the first two beside the title and the third at the far right. Books default to `[author, pages, stores]`.
- **Metadata language** (Settings, F-013) is passed to the source as a language preference.
- **Existing custom type named "Book":** the migration must not break it; if its key collides with the new built-in key, the custom one keeps its data and the orchestrator picks the least surprising rename, flagged.

## User stories
### Backend
- **F016-B1 · Source check.** Terms, rate limits, caching and cover use of the chosen source; quality on 6 sample titles (English, Italian, French, an exact ISBN, a misspelling, a translated title). Report with the decision before building. No retention duty is expected for open data (D-089 applies to TMDB); say so if it differs.
- **F016-B2 · Book type.** Migration seeding the built-in `book` type with its fields (`author`, `pages`, `first_publish_year`, `isbn`, `stores`), default pins `[author, pages, stores]`, price allowed; idempotent, tested with `make test-backup`; collision handling above.
- **F016-B3 · Lookup.** Suggestions, create-with-lookup, fill, re-match and refresh for books, reusing the F-013 lookup flow (generalise it to several providers rather than copying it); cover stored through the image pipeline; the item keeps the source id for refreshes; `lookup_disabled` works as for movies. Tests use a fake server or fixtures, never the real network; the test stack gets a deterministic fixture for one book query like the TMDB one (D-090).
- **F016-B4 · Stores field.** A `stores` field holding provider keys, validated against a fixed provider list; link building from ISBN or title in one place; a workspace setting for the preferred stores.
- **F016-B5 · Three pins.** `pinned_fields` accepts at most 3 keys, on every type; migration-free.
- **Contract:** `api-v0.12.0`; `make test-backup`; `make audit` before the `v2.1.0` tag (D-084).

### Web
- **F016-W1 · Book lists.** "Book" is offered in the new-list and change-type menus; items show author, pages, ISBN, first publication year and "Where to get it" in "+ Add field" and in the detail, with the cover.
- **F016-W2 · Lookup.** Title suggestions, first-result fill, "Wrong match?", re-match and refresh for books, with the same UX as movies (poster becomes cover).
- **F016-W3 · Row layout.** Rows render up to three pins as above (compact, thumbnail and grid): writer with the title, pages next to it, store tiles on the far right; pinned-field picker and Settings → Types & fields allow 3 pins. Looks right at 375 px.
- **F016-W4 · Stores UI.** A multi-choice dropdown like the streaming platforms, in the item and as a preferred-stores choice in Settings; provider tiles use the shared icon tile (letter tile until F-017 supplies the final icons).
- **Release:** web 2.7.0; update the affected e2e specs and add one for a book (suggestion, fill, layout, stores) against the test stack fixture; `npm run audit` before the `v2.7.0` tag. Both themes keep zero serious or critical axe findings.

## Contract impact
`api-v0.12.0` (additive: the `book` type, its lookup, the stores field and setting, pins up to 3). Web W1 to W4 pin to it.

## Constraints
- Lean workflow D-079/D-081 with the AI-agnostic tiers (D-087): complex worker tier for B2 and B3 (migration, generalised lookup), simple for the rest.
- Keep Frosted Gallery and D-083; the user-facing word is "type" (D-094).
- The API key, if the final source needs one, goes in `deploy/server/.env` and `.env.example` (parent, top-level orchestrator).

## Out of scope
Per-country store availability, audiobooks, series and reading status, the icon audit (F-017), the type refactor (F-018).

## Open questions
| ID | Question | Default |
|---|---|---|
| F016-Q1 | Which stores are offered | Open Library, Bookshop.org, Amazon, Apple Books, Google Play Books, Kobo |
| F016-Q2 | Pins above 3 | No, 3 is the maximum |

## Repo breakdown (filled by the repo orchestrators)

### Backend

#### F016-B1 · Source check report (backend orch., 2026-10-19)
**Decision: Open Library. No API key needed.** Google Books is not needed as a fallback, and a key would be needed only if it were: an unauthenticated request to Google Books today returned `429 RESOURCE_EXHAUSTED` (daily quota 0 for keyless use).

Sources: [Open Library API guide](https://openlibrary.org/developers/api), [Covers API](https://openlibrary.org/dev/docs/api/covers), [licensing](https://openlibrary.org/developers/licensing). Checked 2026-10-19 with live requests.
- **Terms.** The API is meant for "open, mission-aligned" apps that help people find books in real time, not as a bulk data backend. Rules: cache responses, identify the app with a `User-Agent` carrying a contact email, do not scrape HTML, do not crawl the covers API. Violations may get rate limited or blocked. No retention duty is stated (the data is open and has monthly dumps), so **D-089 does not apply**: imported book data and covers may be kept indefinitely.
- **Rate limits.** 1 request/second unidentified, **3 requests/second identified** (User-Agent with app name and email). The client paces itself well below that and caches suggestions briefly, like the TMDB client.
- **Covers.** `https://covers.openlibrary.org/b/id/<cover_i>-M.jpg?default=false` (404 instead of a blank image when missing). Allowed for display; we fetch **one cover per imported item** (a user action, not a crawl) and store it through the image pipeline.
- **Quality on the six sample titles** (`search.json`, `lang` preference where relevant):
  | Case | Query | Result |
  |---|---|---|
  | English | `the hobbit` | The Hobbit, Tolkien, 1937, 310 p., cover: correct, first |
  | Italian | `il nome della rosa` (lang it) | Il nome della rosa, Eco, 1980, 533 p., cover: correct, first. `la ragazza di Bube`, `il signore degli anelli` also correct |
  | French | `le petit prince` (lang fr) | Le petit prince, Saint-Exupéry, 1943, 96 p., cover: correct, first. `cent ans de solitude` returns the Spanish edition first, the French one second |
  | Exact ISBN | `isbn:9780441172719` | Dune, Frank Herbert, 1965, 608 p., cover: correct, single result |
  | Misspelling | `dun frank herbart` | **0 results.** There is no fuzzy matching, a clear typo finds nothing (the item is created unchanged, as for TMDB) |
  | Translated title | `lo hobbit` (lang it) | Finds The Hobbit (work-level match through other editions), correct but under the English title |
  Weak points to accept: no typo tolerance; a translated query is matched at work level and the title comes back in the work's main language; `number_of_pages_median` is a median over editions, not the user's edition. Open Library does not need to be perfect here: "Wrong match?" and manual editing exist.
- **Fields mapped.** Search with `fields=key,title,author_name,first_publish_year,number_of_pages_median,isbn,cover_i` gives writer, pages, first publication year, an ISBN and the cover id in one call; the work id (`/works/OL…W`) is the stable source id for refresh.

#### Tasks (one branch `feature/F016-books-type`, one PR; workers write code and tests but run no tests, D-079/D-081; sequential on one branch because the migrations are numbered in order)
| Task | Story | Tier | What |
|---|---|---|---|
| T1 | F016-B5 | simple (Haiku 5.5) | Pins up to 3 on every type: spec `maxItems: 3` (lists and type defaults), `ValidatePinned`, no migration; `make generate` |
| T2 | F016-B4 | simple (Haiku 5.5) | `internal/stores` (fixed provider list, single link builder from ISBN/title/Open Library id), field type `stores`, `workspace_settings.preferred_stores` + settings API; migration 000019 |
| T3 | F016-B2 | **complex (Sonnet 5.5)** | Migration 000020: built-in `book` type + fields + default pins + `allows_price`, collision handling for an existing custom type with key `book`, idempotent seed functions |
| T4 | F016-B3 | **complex (Sonnet 5.5)** | Generalise lookup to several providers (migration 000021 `tmdb_imports` to `lookup_imports`), Open Library client, endpoints, fixture; D-088 to D-092 behaviour kept for TMDB |
Orchestrator then reviews FLAGS, `docs-keeper`, runs `make check` once and `make test-backup`, opens and squash-merges the PR, tags `api-v0.12.0`, runs `make audit`, tags `v2.1.0`.

### Web (web orchestrator, 2026-10-19). One PR, web 2.7.0, pinned to `api-v0.12.0`; blocked until the backend tags it. Order: T0 → T1 → T2/T3 → T4 → T5.
| Task | Story | Tier | Scope |
|---|---|---|---|
| T0 | all | orchestrator | `npm run api:sync -- api-v0.12.0`, check the generated diff, bump to 2.7.0, update dev/test fakes (`mocks/types.ts` gets a `book` definition). |
| T1 | W1 | simple | Book in the new-list and change-type menus (comes from the types API); author, pages, ISBN, first publication year and stores in "+ Add field" and the detail; cover as the item image. Mostly data-driven: check `items/types/index.ts` and `inline/fields.ts` for hard-coded type keys. |
| T2 | W2 | simple | Generalise `items/TmdbTitleField.tsx` (suggestions, first result on commit, Wrong match?, re-match, refresh) to book lookups; poster becomes cover; settings hint "filled from TMDB" becomes source-neutral. Reuse, do not copy. |
| T3 | W3 | **complex** | `MAX_PINNED` 2 → 3 in `lists/pinned.ts`; `pinnedPlacements` returns `{ first, second, third }` (1 pin: beside the title; 2: unchanged, so movies and TV are untouched; 3: two beside the title, third far right; the TV `5×7` combination is kept); `ItemEntry.tsx` compact, thumbnail and grid layouts (lines ~106–190), checked at 375 px; `PinnedMenu` and Settings → Types & fields allow 3 (`aria-description` "of 3"). Rows with a stores pin render the tile run via the shared `ServiceIcon`. |
| T4 | W4 | simple | Stores multi-choice (clone `inline/StreamingPlatforms.tsx` over the provider list from the API), preferred stores in Settings → Media (`SettingsForm.tsx`, `form.ts`, `mocks/devSettings.ts`); store tiles via `ServiceIcon` with the neutral letter tile fallback (no logos, F-017). |
| T5 | release | simple | e2e: update affected specs (`10-tmdb`, `11-custom-fields`, `02-item`, `08-a11y` as needed), add `12-book.spec.ts` (suggestion, fill, three-pin layout, stores) against the test-stack fixture; unit tests per task. |

Gate, once at the end by the orchestrator: `npm run check`, `npm run e2e` on a fresh `./deploy/test up -d --fresh`, `npm run audit`. Workers write code only and do not run tests. `[CRUCIAL]` review: the placement logic (T3) and the lookup generalisation (T2).

## Log
- 2026-10-19: planned from the user's request.
