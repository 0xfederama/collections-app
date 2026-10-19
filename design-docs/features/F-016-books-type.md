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

## Log
- 2026-10-19: planned from the user's request.
