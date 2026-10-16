# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Users
Two trusted people (a couple) sharing one workspace. No accounts, no identity: edits are anonymous. They use it on
desktop and phone browsers, over localhost or a private network (LAN, VPN, Tailscale). The job: collect things they like
or want (movies to watch, motorcycles to consider, things to buy), then look at them, compare them and decide together.

## Product Purpose
A calm, image-forward shared place to collect and compare things. One workspace holds nested folders, lists and items.
Items carry one image, structured fields and a Markdown description with version history. Success is that browsing a list
feels like a polished collection product, not an admin dashboard or a project-management tool.

## Positioning
What the user says it must do better than a notes app or spreadsheet: show the image, offer structured per-kind fields
(price, movie runtime, motorcycle specs, etc., ideally filled in automatically rather than typed), and keep free-form
Markdown notes with history, all on the same item. How much automatic filling exists today is not confirmed here: check
the backend and `design-docs/PRODUCT.md` before claiming it.

## Operating Context
- Workspace: exactly one, auto-created. Folders nest without a depth limit; lists live at the root or in a folder.
- Items belong to one list. Kinds: generic, movie, tv_show, motorcycle, car, camera. All kind fields are optional.
- Lists have a display mode (compact, thumbnail, grid) and a sort mode (manual, title, updated).
- Trash with restore, global search, Settings, Markdown editing with Edit/Preview and a History panel.
- Layout breakpoints and screens are specified in `design-docs/UI_SPEC.md`.

## Capabilities and Constraints
- Stack: React 19, TypeScript, Vite, Tailwind 4, Radix UI primitives, dnd-kit, CodeMirror 6, Fontsource (Fraunces, Inter).
- The API must never be exposed publicly (no auth in the MVP). Same-origin `/api`, no CORS.
- Missing images must never show a broken-image glyph: fall back to a tinted tile with the kind icon.
- Status is text, never color alone. Reordering has a keyboard alternative.
- Web code lives in the `frontend-web/` submodule; design changes go through that repo's own branch and PR.
- Terminology: workspace, folder, list, item, kind, trash.

## Brand Commitments
No fixed brand. The docs' tone is "calm" and "image-forward". The user is open to a redesign: current look (including
Fraunces and Inter) is evidence, not binding.

## Evidence on Hand
Real screens exist in `frontend-web/` (v1.0.0 released). No testimonials, usage data or brand assets exist; do not invent any.

## Product Principles
- Images lead; chrome recedes.
- Structured fields should save typing, not add forms.
- Calm and personal, never admin-dashboard dense.
- Two people, one shared space: no accounts, no ceremony.
- Nothing is lost: trash and version history are part of the trust.

## Accessibility & Inclusion
Keyboard support for all interactions (including reorder) and status never conveyed by color alone. The docs target
WCAG 2.2 AA; confirm before treating it as a hard requirement.
