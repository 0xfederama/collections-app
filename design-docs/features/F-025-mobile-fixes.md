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

## Acceptance
- e2e on a mobile viewport (Playwright device emulation, WebKit where possible) covers W2, W3, W5 and the 16px rule of W1; desktop e2e still passes.
- Checked on `./deploy/dev`; the user checks on the Pi test stack after a pre-release.

## Log
- 2026-11-04: brief written.
- 2026-11-04: W1–W7 done (web#109, web 2.23.0, D-120). Mobile-webkit e2e 5/5; desktop e2e 55 pass + 1 flaky dark-mode contrast check in `09-list-icons` (passes alone). To check on a real phone: long press in manual sort, rows outside manual sort, the floating menu button on loading/error pages.
