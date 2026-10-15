---
version: 1
slug: "frontend-web-src-layouts-appshell-tsx"
primary_target: "frontend-web/src/layouts/AppShell.tsx"
related_targets: []
---

# Collections web app: shell, list, item detail, quick add (web 2.0.0)

Mode: Operate. Scope: every screen of frontend-web; the shell, list view, item detail and quick add carry the direction.

## Job and constraints
Two people (a couple) collect, browse and compare things on desktop and phone. Images lead, chrome recedes, calm and personal.
Operate rules: standard controls, scanability, a clean grid. Light and dark are both required, axe zero, keyboard paths intact.

## Chosen direction: Frosted Gallery (Apple-inspired depth, not Liquid Glass)

## Direction contract
THESIS: Chrome is frosted material floating over the content; colour comes only from the accent and from real images, if any. It refuses the flat admin dashboard and the flat colour-field look.
OWN-WORLD: Cool light grey ground (#EDEEF1) with a faint ambient gradient; translucent sidebar, floating toolbar and detail sheet (backdrop blur + saturate, 1px hairline, inner top highlight, soft layered shadows); white cards with a 6px inner image inset and radius 18; graphite dark theme with the same materials; system font stack (SF on Apple, system-ui elsewhere), no web font; one restrained indigo accent (#4F46E5 light, lifted in dark) used only where something can be acted on; neutral tiles everywhere images are missing or dull (kind icon or initial), no per-list colours.
STORY: Open a list, see the images, click a card, edit anything in place from the detail sheet, add things from anywhere with one quiet dialog.
FIRST VIEWPORT: Desktop, three columns: 268px frosted sidebar (name, search, New item button, list tiles with counts, Trash and Settings last), main with a floating pill toolbar (display mode segmented control, sort, filter), title with the kind chip next to it, rows (or a 4-up card grid with fallback tiles); right a floating 420px detail sheet with hero, title field in edit state with explicit check and cross buttons, pen fields on hover, streaming service icons (with a $ badge when paid), "Click to start writing", and "+ Add field". Primary action: New item in the sidebar.
FORM: Operate shell with standard controls; seed reference: seed:18725b40 (user-pinned Apple reference overrode the catalog roll; Frosted Gallery was the roll's assigned card).
SIGNATURE: Materials change with context: the toolbar and sheet blur what scrolls behind them; the quick-add dialog dims the app and lets the same material float above it. 150-200ms ease-out, springs only on press.
GUARDRAILS: blur only on sidebar, toolbar, detail sheet and dialogs; solid fallbacks under `@supports not (backdrop-filter)` and `prefers-reduced-transparency`; contrast checked on glass over the lightest and darkest images; reduced motion respected.
FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance
