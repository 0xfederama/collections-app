# F-026 — List polish, availability filters, unique titles

Status: brief (2026-11-05). Repos: backend, frontend-web. Workflow v2 lean.

## Decisions (user, 2026-11-05)
- Titles are unique within a list (case- and accent-insensitive, trimmed). Enforced by the backend on create, rename, move and copy: `409` with a clear code; the web shows it inline. No DB constraint and no migration (existing duplicates stay; the rule applies to new writes).
- Two new movie/TV filters, server side because lists are paginated: **Available** (at least one streaming offer on a service the user owns, or any service when the user owns none) and **Available, not paid** (same, but included in the subscription: flatrate/free/ads, no rent or buy).

## Stories
- B1 backend: the two availability filters on the list items endpoint (contract + docs), using the stored streaming data and `owned_streaming_services`.
- B2 backend: unique titles per list (409 `duplicate_title`), on create, rename, move, copy.
- W1 web: search field without the white/outlined border, same look as the other toolbar buttons.
- W2 web: adding a new item focuses the title field and opens the keyboard on phones.
- W3 web: compact list rows show only the length (runtime / pages), no director or author.
- W4 web: the two availability filters in the Filter menu (movies and TV lists only).
- W5 web: back controls: every back arrow goes to Home, except the item page's, which goes to the item's list. Check and fix where it differs.
- W6 web: the new-item title field matches the height of the ✓/✕ buttons next to it.
- W7 web: show the backend's `duplicate_title` error inline in the new-item and rename flows.
- W8 web: drop "(draft)" from the new-item view.

## Log
- 2026-11-05: brief written.
- 2026-11-05: backend B1 (PR 0xfederama/collections-app-backend#78, contract `api-v3.2.0`: `listItems?availability=available|included`, 409 `duplicate_title`) and B2 (#79) merged; released as `v2.11.0`. Web builds against `api-v3.2.0`. Open: lookup refresh/rematch can still overwrite a title into a duplicate; the Go streaming registry mirrors the web's `streamingEntries.ts`.
- 2026-11-05: B2 follow-up (user): duplicates keyed on the provider id (`tmdb_id`, `openlibrary_id`) when both items have one, else on the title; remakes may share a title. Released as `v2.11.1`. The refresh gap is closed (refresh never changes the id).
- 2026-11-05: rule revised (user, D-126): id-only on movie/TV/book lists, titles on generic lists; `v2.11.2` (#81). Rematch left unchecked (unused by the web). Contract stays `api-v3.2.0`.
- 2026-11-05: web W1–W8 done (2.29.0, D-127). Both promoted to prod by the user. F-026 complete.
