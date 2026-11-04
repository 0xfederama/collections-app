# F-025 — Mobile fixes

Status: brief (2026-11-04). Repos: frontend-web only. Workflow v2 lean. Roadmap #23.

## Decisions (user, 2026-11-04)
- The web app on a phone should behave like a native mobile app.
- The "lighter web app" audit is deferred: it will lean on e2e coverage later, not part of this feature.
- No backend change, no migration.

## Stories (web)
- W1 **No zoom on focus**: focusing an input, select or textarea on iOS Safari must not zoom the page. Prefer the root cause (form controls at 16px or more on touch devices); a `maximum-scale=1` viewport is an acceptable addition if needed. No horizontal page scroll.
- W2 **One-row list toolbar**: on phone widths, search, filter, sort and the trailing + fit on a single row (compact controls, icon buttons, search field flexes).
- W3 **Compact mobile header**: the hamburger no longer takes a full top row of its own; it shares the row with the page title/toolbar (or an equivalent compact pattern).
- W4 **Sidebar padding**: in the open mobile sidebar, buttons/rows lose the excess left and right padding, aligned with the sidebar edges.
- W5 **Long press on list entries**: holding an entry opens its actions (at least Move and Delete). Drag-and-drop reorder keeps working (e.g. hold still = menu, hold and move = drag, or a drag handle); no conflict with scrolling.
- W6 **Smaller link icons** (all widths): the Google, Letterboxd, IMDb, streaming services and other link icons in the expanded item are smaller.
- W7 **Remove the hint** (all widths): drop the "switch to manual sorting to…" line.

## Follow-up stories (user, 2026-11-04)
- W8 **Filter and sort controls**: filter uses the mobile icon button at all widths; sort becomes a matching control labelled "Sort" (not the current sort value), coherent with Filter. The active sort stays visible inside its menu (and as a small indicator if needed).
- W9 **Row metadata**: movie rows always show the director next to the runtime; book rows show the author with the page count before it. Lowest priority: dropped first when space is short. Streaming services (movies) and author (books) win over the other fields.
- W10 **Menu button in the page header**: no floating button. One leading slot in each page's own header row: top-level pages show the menu icon there, sub-pages (item page) show the back control there and the menu stays reachable from the list. The title never shifts under or around an overlay.
- B1 backend **Latin-script names**: movie/TV titles and person names (directors) come in the app's language; when TMDB only has a non-Latin form (Korean, Japanese, Chinese, Cyrillic…), fall back to the English translation, then a Latin `original_title` / `also_known_as`, before the non-Latin original. Optional backfill for stored items.

- B2 backend **Weekly movie and TV refresh** (D-123): maintenance refreshes every movie and TV series weekly, overwriting all fetched fields including user edits, keeping user images; books never; keep the `refresh` mode with the same overwrite rule and add a list-level refresh.
- W11 **List polish + Refresh details**: "Refresh details" in the list page's … menu; less vertical space between the description and the toolbar; search becomes an icon button on phones like Filter/Sort (expands on tap); no white band at the bottom of the page on iOS Safari (safe area, page background).

- W12 **View switcher**: same height and style as the other toolbar buttons, moved to the left end of the toolbar row (web and mobile).
- W13 **No auto-open on create (phones)**: creating an item on a phone keeps the user on the list instead of opening the item.
- W14 **Home as the root page (phones)**: on phones the drawer is merged into Home ("Library" idea superseded), iOS Mail/Notes/Files pattern): folders and lists as rows, Settings and Trash as normal rows in their own section at the end (no bottom bar). Tapping a list pushes it; the list's leading slot shows a back control to Library instead of the hamburger. Desktop keeps the sidebar.

## Acceptance
- e2e on a mobile viewport (Playwright device emulation, WebKit where possible) covers W2, W3, W5 and the 16px rule of W1; desktop e2e still passes.
- Checked on `./deploy/dev`; the user checks on the Pi test stack after a pre-release.

## Log
- 2026-11-04: brief written.
- 2026-11-04: W1–W7 done (web#109, web 2.23.0, D-120). Mobile-webkit e2e 5/5; desktop e2e 55 pass + 1 flaky dark-mode contrast check in `09-list-icons` (passes alone). To check on a real phone: long press in manual sort, rows outside manual sort, the floating menu button on loading/error pages.
- 2026-11-04: B1 done (backend#73, tag v2.8.4 with a draft release, D-121). Existing items: use the per-item lookup refresh.
- 2026-11-04: W8–W10 done (web#110, web 2.24.0, D-122); e2e 59/59 (51 desktop, 8 mobile-webkit); 09-list-icons flake fixed. Open: lookup refresh overwrites a user-edited director (docs say edits survive).
- 2026-11-04: B2 done (backend#74, tag v2.9.0 with a draft release, D-123, D-124). Open: confirm the TMDB terms allow keeping weekly-refreshed data indefinitely; later contract release drops the legacy retention columns.
- 2026-11-04: W11 web parts 2–4 in progress (`feature/f025-w11`). Part 1 "Refresh details" waits for the backend list-level refresh (D-123): not in backend main, api-v3.0.0 or any PR; 2.25.0 ships once it lands.
- 2026-11-04: B2 amended (backend#75, v2.10.0 draft, api-v3.1.0, D-125): refresh mode kept, list refresh added; v2.9.0 superseded. Web: list page … menu calls POST /lists/{id}/lookup-refresh and repeats while remaining > 0.
- 2026-11-05: W12–W14 and polish done (web 2.26.0–2.28.1); backend B2 refresh on demand (2.10.0, D-125). Promoted to prod by the user. F-025 complete.
