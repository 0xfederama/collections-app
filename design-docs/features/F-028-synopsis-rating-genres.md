# F-028 — Synopsis, TMDB rating and genres from the lookups

Status: done (2026-11-16). Repos: backend, frontend-web. Roadmap row 38.

## Why
Movies, TV shows and books are filled from TMDB / Hardcover / Open Library (F-013, F-016), but the item still has no
plot summary, no rating and no genres. The user wants an IMDb-like summary of what the title is about (the short text
under the genres on an IMDb page), a rating to sort by, and genres to filter by.

## Decisions (user, 2026-11-16)
1. **Synopsis → the item's own description, only when it is empty.** On lookup, match, re-match and refresh, the
   provider's summary (TMDB `overview`; for books the Hardcover or Open Library description) is written into the item's
   Markdown description **only if the description is empty**. It is plain text, as one Markdown paragraph. No separate
   synopsis field.
   - After that it is the user's text. It is never overwritten once the user edits it.
   - TMDB terms (D-089, max six months of caching): until the user edits it, the written synopsis is tracked like the
     other imported fields (provenance), refreshed with them, and removed on expiry if a refresh fails. Once the user
     edits the description, it is no longer imported data and is never touched again. The backend decides how to detect
     "unedited" (e.g. a hash of the imported text, or the content version it wrote); record it.
   - Language: the workspace metadata language (F-013); if TMDB has no summary in that language, fall back to English.
     Same idea for the book providers, best effort.
   - It goes through the normal content versioning: one new content version, authored by the system/lookup, visible in
     the item's history.
2. **Rating = the TMDB user score** (`vote_average`, 0–10, one decimal), movies and TV only. Not the IMDb rating: TMDB
   doesn't return it, and the user chose no extra provider. Stored as imported metadata (provenance, refresh, expiry
   like the rest). Also store the vote count if cheap; an average from a handful of votes is noise (the web may show it
   with the count, the backend may treat a very low count as no rating; decide and record).
   - **Sortable** in movie and TV lists (descending by default, items without a rating last).
   - **Not a pinned field** (never in the row). Shown in the expanded item's details only, labelled as the TMDB score.
3. **Genres** for movies and TV: TMDB `genres` names in the metadata language, stored as imported metadata (same
   provenance rules).
   - **Filterable** in movie and TV lists: a multi-select in the Filter menu built from the genres present in that list
     (any-of match), server side because lists are paginated, alongside the F-026 availability filters.
   - Shown in the expanded item as small chips (like IMDb's), not pinned.
   - Books: genres not required. Add them only if the provider gives clean ones cheaply; otherwise out of scope.
4. **Existing items** get the new data through a generic backfill: every item already linked to a provider id is
   refreshed once (throttled, within TMDB / Hardcover / Open Library rate limits; idempotent; resumable). The same rules
   apply: the description is filled only where it is empty. Structure-only migration plus this generic backfill, never
   data-specific.
5. User-entered values are still never silently overwritten (F-013). Genres and rating are imported-only fields (no
   manual editing in this feature).

## Stories
- **B1 backend · Import.** TMDB detail requests also read `overview`, `vote_average` (+ `vote_count`) and `genres`
  (metadata language, English fallback for an empty overview); book lookups read the description. Stored with the
  existing provenance/refresh/expiry machinery (D-089).
- **B2 backend · Synopsis into the description.** Fill an empty description on lookup/match/re-match/refresh as decision 1,
  with the "unedited imported text" tracking and removal on expiry.
- **B3 backend · Sort and filter.** `sort=rating` (desc default, nulls last) and a `genre` filter (repeatable, any-of) on
  the list items endpoint for movie/TV lists; an endpoint or field giving the genres present in a list for the filter
  menu. Contract minor bump.
- **B4 backend · Backfill.** One generic, throttled, resumable refresh of all provider-linked items; progress in the logs.
- **W1 web · Item.** Expanded item: genre chips and the TMDB score (with vote count, if kept) for movies/TV; the filled
  description shows as the normal description.
- **W2 web · Sort.** "Rating" in the movie/TV list sort menu.
- **W3 web · Filter.** Genres multi-select in the movie/TV Filter menu, from the list's genres, combined with the
  availability filters; active filters visible as today.
- **W4 web · Attribution.** Check the TMDB attribution in Settings → About still covers the new data (it should).

## Order
Backend first (contract tag), then web against that tag. Backfill runs on deploy of the backend release.

## Out of scope
The IMDb rating (no OMDb or IMDb datasets), manual editing of genres/rating, book ratings, genres for books unless free,
showing the rating or genres in list rows.

## Repo breakdown: backend
Merged as [collections-app-backend#95](https://github.com/0xfederama/collections-app-backend/pull/95) (squash `0ceeadba0dcbec232e35faf417f76727ba7f1797`), backend 3.2.0, contract `api-v4.3.0`, migration 000003 (expand-only). Decisions D-162 (fields, synopsis, unedited detection), D-163 (sort/filter/genres endpoint), D-164 (backfill).
- B1: TMDB `overview` (en-US fallback when empty), `vote_average` → `tmdb_rating` only at ≥ 10 votes, `vote_count` → `tmdb_vote_count`, `genres` names; Open Library work `description`; Hardcover `description` (untracked creates).
- B2: synopsis fills only a never-saved description (version 0) as a `lookup`-origin version; tracked by `description_version` + sha; replaced while tracked; any user save ends it. No expiry path today (D-123 / D-095).
- B3: `sort=rating`, `genre` filter, `GET /lists/{id}/genres`, codes `invalid_sort`, `invalid_filter`.
- B4: generic backfill on `import_generation`, 25 items / 10 min.

## Web handoff
- Item (movie/TV) `metadata`: `tmdb_rating` (number 0–10, one decimal, absent when < 10 votes), `tmdb_vote_count` (number), `genres` (string[], ≤ 10). Lookup-owned: hide them from the editor (like the bookkeeping fields); a PATCH may omit them (kept) or echo them unchanged; a different value → 422 `validation_failed`. Definitions: new field type `text_list` (`genres`).
- Show "TMDB score 7.4 (1,200 votes)" and genre chips in the expanded item only.
- `GET /lists/{id}/items`: `sort=rating` (desc, unrated last); repeatable `genre=` (any-of, case-insensitive); both movie/TV only, else 422 `invalid_sort` / `invalid_filter` (also for an empty `genre=`). `rating` is a valid list `sort_mode` for movie/TV.
- `GET /lists/{id}/genres` → `{ genres: [{ name, count }] }` for the Filter menu (`[]` on other types).
- Content: `origin` (`user`|`lookup`) on `GET /items/{id}/content` and on each version info; label lookup versions in history (author null). A lookup can create a new content version, so an open editor may get the usual 412 on save.
- After deploy: the backend refreshes every provider-linked item once in the background (25 items every 10 min; logs `lookup backfill progress`, then `lookup backfill complete`). Movie/TV get score, genres and (if the description was never saved) a synopsis; books get only an empty description filled. Resumes after restarts; no action needed.
- W4: TMDB attribution in About already covers it.

## Repo breakdown: web
- **W1** `items/TmdbDetails.tsx` + `items/tmdbData.ts`: genre chips and "TMDB score 8.4 (40,750 votes)" on the expanded movie/TV item; the keys are hidden from the type fields by `useTypes`.
- **W2** "Rating" in the movie/TV Sort menu (`sort=rating`, default sort too).
- **W3** Genre checkboxes in the Filter menu from `GET /lists/{id}/genres`, any-of `?genre=`, with availability; "Genre: X" chips (`lists/GenreFilter.tsx`, `genres.ts`, `useGenreFilter.ts`).
- **W4** About attribution unchanged (already covers it). History labels lookup versions "Imported summary".
- Also fixed: a type-field save dropped `tmdb_id` / `openlibrary_id` (D-165).

## Log
- 2026-11-16: brief written (user decisions: TMDB score, synopsis fills an empty description).
- 2026-11-16: backend B1–B4 merged (backend#95, `0ceeadba`), backend 3.2.0 / `api-v4.3.0` waiting for tag + release; web next.
- 2026-11-16: web W1–W4 merged (web#154, `e144eeb`), web 3.6.0 on `api-v4.3.0` (tag pushed at the user's request), D-165; waiting for release.
- 2026-11-16: backend#96 keeps omitted `tmdb_id`/`openlibrary_id`/`lookup_disabled` on PATCH (no contract change); `v3.2.0` tagged at `be5245d`, `api-v4.3.0` at `0ceeadb` (same contract).
- 2026-11-16: released: backend 3.2.0 and web 3.6.0 published (test stack, then latest); prod verified (new `/genres` route, new web bundle). Done.
