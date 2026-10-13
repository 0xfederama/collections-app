# Acceptance Tests (Definition of Done)

Levels: **U** = unit, **I** = backend integration (real Postgres via testcontainers, real temp `DATA_DIR`),
**C** = contract (spec lint, generated-code drift), **W** = web component test (Vitest + MSW), **E** = Playwright e2e against the real backend,
**M** = documented manual check.

Test writing is usually dispatched to the `test-writer` subagent (sonnet). The main session reviews the tests and runs them itself (AGENT_WORKFLOW §2).
Each test name or describe block references the AT id (e.g. `TestAT07_ImageSourceExclusive`, `describe("AT-09 …")`).

| ID | Requirement | Levels | Verifiable criteria |
|---|---|---|---|
| AT-01 | Fresh clone setup | M, E | An agent with no prior context follows only the two READMEs on a clean machine, reaches a working app, and records any doc fixes needed |
| AT-02 | Idempotent bootstrap | I | Start the API 3× (including concurrently) → exactly 1 workspace and 1 settings row; data from run 1 survives |
| AT-03 | Hierarchy, move, order | I, E | Create nested folders and lists; move list root→folder→root; reorder siblings; `sort_order` persists; moved resource is appended last |
| AT-04 | Cycles rejected | I | Move folder into itself → 409 `cycle_detected`; into grandchild → 409; DB unchanged |
| AT-05 | Item fields and kind metadata | U, I, W | Validators accept or reject each field rule (title length, price rules, currency required, min ≤ max, URL schemes incl. `javascript:` rejected, every kind's fields per DATA_MODEL §2.1 incl. ranges, enums, `end_year ≥ first_air_year`, `electric_range_km` only for electric/plug-in, IMDb pattern; unknown metadata keys rejected); kind change resets metadata; the UI renders an edit form for each of the 6 kinds |
| AT-06 | Image upload | I, E | JPEG/PNG/WebP accepted; SVG, a PNG renamed to `.svg`, a text file renamed `.jpg`, a 10 MiB+1 file, and a > 40 MP image are each rejected with the right code; replace deletes the old file after commit; remove works; files survive `docker compose restart` (M) |
| AT-07 | Image source exclusive | I | PUT url after upload → upload removed, url set; PUT upload after url → url cleared; DB CHECK rejects both being set (direct SQL test) |
| AT-08 | Markdown safety and versions | U, I, W | `<script>`, `javascript:` links, `onerror` attrs not rendered; > 1 MiB → 413; identical save creates no version; with limit=2 after 5 saves exactly 3 versions remain; restore creates new version |
| AT-09 | Concurrent edit → 412, draft kept | I, W, E | Two sessions load item; A saves; B saves → 412 with `current_version`; UI shows banner, draft intact, Copy works (clipboard and fallback), Reload asks confirmation |
| AT-10 | Missing If-Match → 428 | I | Every endpoint in API §3 "Requires If-Match" returns 428 without the header and with `If-Match: *` (table-driven test generated from the list) |
| AT-11 | Trash | I, E | Delete folder → its lists and items vanish from tree, lists, search, and GET (404); separately-deleted older item stays in Trash after restoring the folder; restore with trashed parent → 409 `parent_in_trash`; restore with destination works; purge removes rows and image files, including nested older batches |
| AT-12 | Search | I, E | Case-insensitive substring (`MAT` finds "The Matrix"); `%` and `_` treated literally; trashed and inside-trashed excluded; path correct |
| AT-13 | Three external links | W, E | Exactly 3 controls in order; Google and Reddit URLs correctly encoded (title with `&`, `#`, quotes); movie adds year, TV show adds "TV series"; official disabled when absent, never a search; `rel="noopener noreferrer"` |
| AT-14 | Responsive and a11y | E | Playwright at 375, 768, 1024, and 1440 widths: navigation works (drawer / rail / sidebar); axe has 0 serious or critical issues on all routes **in both light and dark themes**; theme follows system by default, the override persists across reloads, and there's no flash of the wrong theme; full keyboard-only flow creates list → item → edit → save |
| AT-15 | Contract current | C | Backend: spec lints, generated server code has no diff. Web: lock hash matches the vendored spec, generated client has no diff |
| AT-16 | Quality gates | C | Both repos' `make check` / `npm run check` cover ARCHITECTURE §6 and pass (local gates for now, D-031) |
| AT-17 | Backup / restore round trip | I, M | Script: seed data (items with images, multiple content versions, trash) → backup → wipe → restore into fresh volumes → `verify-restore` checks row counts, every attachment file exists with matching sha256, and latest content bodies match |
| AT-18 | Not publicly exposed | M, C | Default compose publishes `127.0.0.1:8080` only (`make check` greps the rendered `docker compose config`, D-031); README documents the opt-in risk |
| AT-19 | Scope fence | M | Reviewer checklist: no auth, TMDB, AI, public-API, or WebSocket code, tables, or deps in either repo |
| AT-20 | Storage failure recovery | I | Simulated crash after file write before DB commit leaves an orphan file → sweeper removes it (with injected clock > 1 h); file deletion failure after purge is retried by the sweeper; never a dangling DB reference |
| AT-21 | Reorder validation | I | Duplicate ID, missing ID, foreign ID, or trashed ID → 409 `order_stale`; valid → `sort_order` 0..n-1 |
| AT-22 | Unsaved changes guard | E | Edit field, click another list → dialog; cancel keeps edits; confirm discards |
