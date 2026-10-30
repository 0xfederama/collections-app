# F-021 — Web restyle ("Editorial")

Status: **done** (2026-10-30, web#96, `v2.20.0`)    Release: web 2.20.0 (minor)    Roadmap: ROADMAP.md (frontend restyling, next after F-017)
Repos: web only (no backend, no contract change)    Approved by the user: 2026-10-30

## Why
The Frosted Gallery look (F-002) feels soft and generic: very round controls (12 px buttons, 18 px cards, 24 px dialogs), blur
materials, an indigo accent and the system font. The user wants a crisper, more editorial look, taken from
compraresponsabilmente.it: a geometric display face, a quiet UI face, near-white and near-black neutrals, one electric blue and
less rounding. Styling only: every screen keeps its behaviour, markup roles and data.

Mockups (decided with the user on 2026-10-30, private canvas): https://claude.ai/artifact/JhdCKsBFfYiWPzz238Wt13 — list view,
item page, dark mode, token sheet. The values below are the source of truth when the canvas and this file differ.

## Decisions (user, 2026-10-30)
| Topic | Decision |
|---|---|
| Direction | **Plain editorial.** No frosted blur, no gradients, no glow. Hairline borders do the separating; shadows only on floating layers (menus, popovers, dialogs, toasts). Replaces Frosted Gallery (F-002 direction contract) and UI_SPEC §11 where they differ. |
| Type | **Space Grotesk** (display: list and item titles, section headings, row titles, workspace name), **Geist** (all UI and body text), **Geist Mono** (numbers and small labels: counts, years, pages, prices, keyboard hints, uppercase group labels). All three **self-hosted** (OFL), Latin subset, `font-display: swap`; never fetched from Google at runtime. This reverses the "system stack, no web font" rule (CLAUDE.md gotcha 2026-10-15). |
| Type scale | Display 44 px / 1.02 / −0.035em, 700 (list title, item title). Heading 30 / 1.1 / −0.03em, 700. Section 20 / −0.015em, 600. Row title 15.5 / −0.01em, 600. Body 15 / 1.6. UI 14 / 1.5. Secondary 13. Mono label 12 (uppercase labels +0.06em). Body and UI in Geist 400/500/600. |
| Radius | **8 px** controls (buttons, inputs, selects, menu items, tree rows, tooltips); **6 px** small tiles (row thumbnail, service tiles, checkboxes, skeleton rows); **12 px** containers (cards, covers, menus, popovers, toasts, toolbars); **16 px** sheets, dialogs, drawer; full only for tags (chips, badges, avatars). Nested shapes stay concentric (F008-W6 rule). |
| Accent | **Blue `#2d5bff`** on light (primary buttons, focus ring, selection), link/selected text `#2448d6`, selected tint `#eef2ff`. Dark: accent `#4a72ff`, text `#8fa8ff`, tint `rgb(74 114 255 / 0.16)`. One accent only; the F-012 list-icon colours and the status hues stay (re-check contrast). |
| Neutrals, light | bg `#ffffff`, sidebar `#f7f7f8`, surface `#f6f6f7`, border `#e6e6e9`, soft divider `#f0f0f1`, text `#0b0b0c`, body text `#55555c`, muted `#6e6e78` (darkened from the reference's `#8a8a93` to pass 4.5:1). |
| Neutrals, dark | **Near-black.** bg `#0b0b0c`, sidebar `#121214`, surface `#18181b`, border `#26262b`, soft divider `#1d1d21`, text `#f4f4f5`, body `#a8a8b0`, muted `#8a8a93`. |
| Ink button | Quick add is the one **ink** button (text colour fill: `#0b0b0c` on light, `#f4f4f5` on dark); every other primary action is blue. |
| Density | **Medium rows**, about 68 px: 36 × 50 thumbnail, 9 px vertical padding, title 15.5 px with the first pinned field on its own line under it, the second pinned field on the right in mono. Compact and gallery modes keep their structure with the new tokens. |
| Details | Workspace name in Space Grotesk 19/700 with a decorative accent dot after it (`aria-hidden`). List header: the type and the item count as a two-part chip above the title (accent half + tint half, 8 px outer corners). Sidebar group labels (folders) are mono uppercase 11 px. Counts in the sidebar and years/pages/prices are mono. |
| Screens | **Every screen** in one PR (below). |

## User stories (web)
One branch `feature/f021-web-restyle`, one PR, one gate at the end. Stories are done in order; each is one or more
simple-tier worker tasks that the web orchestrator expands from this file.

- **F021-W1 · Tokens and fonts.** As the user, I want the new palette, radius scale, type scale and fonts as tokens, so that
  every screen changes from one place.
  Acceptance: `src/styles/tokens.css` holds the light and dark values above (semantic names kept where they exist, new ones for
  the type scale and the soft divider); materials (`material`, `material-strong`, `--bg-ambient`) become solid surfaces with no
  blur; the three fonts are self-hosted (Fontsource variable packages or vendored woff2, justified in the PR per D-034, Latin
  subset only) and load under the existing CSP (`font-src 'self'`, checked in the production image); no hard-coded values in
  components; `index.html` theme script unchanged (CSP hash still computed).
- **F021-W2 · Primitives.** As the user, I want buttons, inputs, menus, dialogs, toasts, chips, tooltips, segmented controls,
  the tree and skeletons restyled, so that the app reads as one system.
  Acceptance: all 18 primitives in `components/ui` use the new tokens; button variants primary (blue), ink, secondary
  (bordered), ghost, danger; `/dev/ui` shows every primitive and state in light and dark, including the ink button; the service
  icon tiles keep the D-109 registry (`tile`, `fit`, 18 % inset) and D-110 order, with only the radius and border tokens changing.
- **F021-W3 · Shell and sidebar.** As the user, I want the sidebar, icon rail, mobile drawer and item panel in the new style.
  Acceptance: matches the list mockup (sidebar `#f7f7f8` / `#121214`, hairline divider, search field, ink Quick add, mono
  counts and group labels, tinted current row); collapsed rail and mobile drawer follow the same tokens.
- **F021-W4 · List view.** As the user, I want the list header, toolbar and rows as in the mockup.
  Acceptance: two-part chip, display-size title, description, one toolbar row (search, + Filter, sort, Pinned, display mode,
  New item), medium rows with thumbnail tile and service tiles; compact and gallery modes restyled; empty, loading and error
  states restyled.
- **F021-W5 · Item page.** As the user, I want the item page as in the mockup.
  Acceptance: type label in mono uppercase, display title, secondary line with mono numbers, 44 px link tiles, fields as a
  hairline definition list, "+ Add field" as a dashed ghost button, description section heading in Space Grotesk, Move and
  Delete at the bottom; inline editors, the image dialog, history drawer and description editor follow the tokens.
- **F021-W6 · Every other screen.** As the user, I want Home, Search (dropdown and results page), Trash, Settings (all panes,
  modal), Quick add, the new-item draft, and every dialog (new list, rename, move, change type, list icon, confirmations) in
  the same style, so that nothing looks half-converted.
  Acceptance: a screenshot pass of each screen in light and dark at 1280 and 375 px, attached to the PR.
- **F021-W7 · Docs and release.** UI_SPEC §11 rewritten for "Editorial" (pointing at this file), CLAUDE.md layout and gotchas
  updated (fonts rule, radius scale, materials), `docs/` via docs-keeper; version 2.20.0.

## Constraints (must not change)
- **Styling only.** No behaviour, routing, data, API or contract change. If a story seems to need one, the web orchestrator
  stops and tells the user so it is briefed separately.
- F-020 slice boundaries stay lint-enforced: features imported through `index.ts`; `components/` and `lib/` import no feature;
  no new exemptions. Lucide stays imported only in `components/ui/icons.ts`.
- Five-type model (F-018) and the service icon registry (D-109) with its display order (D-110) unchanged.
- Accessibility: text ≥ 4.5:1 and UI boundaries ≥ 3:1 in both themes (check muted text, chips, borders that carry meaning,
  disabled states, status colours); `:focus-visible` ring 2 px blue with 2 px offset (inset pattern where clipped); no target
  smaller than 44 px on touch (desktop controls may be 36–38 px tall); `prefers-reduced-motion` respected; the e2e axe checks
  stay at zero serious or critical.
- The existing e2e suite stays green with **selector updates only where markup really changes**; no behavioural test edits.
- Same CSP: no inline style attributes, no runtime font or icon fetching.

## Contract impact
None.

## Out of scope
- New features or controls (for example a "watched" checkbox or status: the app has none today, so the mockup shows none).
- Layout or information changes beyond what the mockups show; new display modes.
- Gradients, blur, illustration or photography.
- Backend, mobile apps.

## Workflow (lean v2)
- Web orchestrator (Opus 5.5, medium) expands W1–W7 into task specs and dispatches **simple-tier** workers sequentially on the
  one branch; W1 first (everything depends on the tokens), W2 before W3–W6.
- **One gate** at the end: `npm run check` once on the final commit, `npm run e2e` on `./deploy/test up -d --fresh` (the restyle
  touches every flow), `npm run audit` before the tag. A **medium-effort review** of the whole diff before the PR, on top of
  reviewing worker FLAGS (design-system decisions are `[CRUCIAL]`).
- Visual check on `./deploy/test up -d --fresh` (ports 5183/8090), never the user's dev data.

## When it ships
The web orchestrator sends the top-level orchestrator one short message listing the docs to update: ROADMAP (restyle done,
web 2.20.0), a DECISIONS entry for the Editorial tokens and type scale (fonts reversal included), STATUS.

## Open questions
| ID | Question | Default |
|---|---|---|
| Q-F021-1 | Fontsource packages or vendored woff2? | Fontsource variable packages, pinned, Latin only; vendored if a family has none. |
| Q-F021-2 | Row position numbers ("01", "02") seen in the mockup? | Leave out: they would add meaning (order) the list does not have in sorted or filtered views. |

## Repo breakdown (filled by the web orchestrator)
| Task | Story | Branch | Worker result | Flags reviewed | PR |
|---|---|---|---|---|---|
| Tokens, fonts | W1 | feature/f021-web-restyle | done | yes (contrast fixes on dark accent-fg and border-strong) | web#96 |
| Primitives | W2 | same | done | yes | web#96 |
| Shell, list view | W3, W4 | same | done | yes (count stays after items, chip shows the number too) | web#96 |
| Item page, other screens | W5, W6 | same | done | yes | web#96 |
| Review fixes, docs, 2.20.0 | W7 | same | done (6 review findings fixed) | yes | web#96 |

## Log
- 2026-10-30: direction decided with the user on the mockup canvas; brief drafted and approved; web orchestrator started W1.
- 2026-10-30: shipped as web 2.20.0 (web#96). Q-F021-1: Fontsource packages. Q-F021-2: no row numbers. Folder names in the sidebar stay normal text (mono uppercase truncated badly); display size is fluid (32 px on phones).
