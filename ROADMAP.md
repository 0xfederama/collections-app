# Collections App — Product Roadmap

| | |
|---|---|
| **Owner** | Top-level orchestrator (parent repo session), approved by the product owner (you) |
| **Last updated** | 2026-11-16 |
| **Horizons** | **In progress**: rows marked 🚧 in §2 · **Future**: wanted, not scheduled (§3) · **Exploring**: uncertain concepts, no commitment (§4) |
| **Status** | ✅ done · 🚧 in progress · 🔭 future |

Target windows are **indicative**, not promises. Order within a horizon is the priority order.
Bigger initiatives get an ID (`F-NNN`) and a feature brief in [`design-docs/features/`](design-docs/features/); small ones are just a row here plus a DECISIONS entry.
IDs follow creation order, not execution order: the **#** column in §2 is the order things run in.

---

## 1. Vision

A calm, image-forward place for two people to collect and compare the things they like or want: movies to watch,
motorcycles to consider, things to buy. It's private and self-hosted on a home server. Data is never lost: there's
version history, a trash with restore, and backups. It should be quick to use on a phone or a desktop.

**Product principles**
1. **Private by default.** The app reaches the internet only through Cloudflare Tunnel behind Cloudflare Access (allowed emails only, D-146); nothing else is exposed. Data stays on your hardware.
2. **Never lose user data.** Edits are versioned, deletes are restorable, conflicts never discard a draft, and backups are verified.
3. **Calm and lean.** Clean UI, few dependencies, no features that need maintenance without being used.
4. **Contract first.** The backend owns the OpenAPI contract, and the web app follows a pinned version.

---

## 2. At a glance

| # | Release | Theme | Status | Window |
|---|---|---|---|---|
| — | **1.0 MVP** | Organize, describe and protect a shared collection | ✅ Released `v1.0.0` (2026-10-15) | Oct 2026 |
| 1 | **1.0.1** | Polish from the release checks (F-006) | ✅ Released `v1.0.1` (2026-10-15) | Oct 2026 |
| 2 | — | Exploration session: you used the fresh test env and listed what to change | ✅ Done (2026-10-15) | Oct 2026 |
| 3 | **1.1.0** | Lists and items restructure + exploration fixes (F-007): one kind per list, trimmed fields, addable price, list description, 6 UI fixes. Last shared version (D-080) | ✅ Released `v1.1.0` (2026-10-15) | Oct 2026 |
| 4 | — | Brief e2e safety net (F-003): `make smoke` + ~8 Playwright specs | ✅ Done (2026-10-15) | Oct 2026 |
| 5 | **web 2.0.0** | UI refresh (F-002): Frosted Gallery design, in-place item editing, quick add, streaming icons; run from a sister session | ✅ Released `v2.0.0` (2026-10-15) | Q4 2026 |
| 6 | **web 2.1.0** | UI polish after the first look at 2.0.0 (F-008): top bar (search + quick add + theme), consistent radii and toolbar, keyboard selection, drag into folders, inline new item, title area, links row with real icons, one price field, initials, generic lists without fields | ✅ Done (2026-10-16) | Oct 2026 |
| 7 | **web 2.2.0** | UI polish 2 (F-009): price only on kinds that have it, ordered pinned fields, Move/Delete at the bottom, one icon tile, cleaner streaming row, centred empty Trash | ✅ Merged 2026-10-16 (2.2.0 bumped in #39, tag pending) | Oct 2026 |
| 8 | **backend 1.4.0 + web 2.3.0** | List icons (emoji or built-in, searchable, coloured), paste an image, empty trash, trash auto-purge (F-012, `api-v0.8.0`) | ✅ Released `v1.4.0`, `v2.3.0` (2026-10-16) | Oct 2026 |
| 9 | **backend 1.5.0 + web 2.4.0** | TMDB lookup: smart title match, auto-filled fields, poster, director (sort/filter), metadata language, attribution (F-013, `api-v0.9.0`) | ✅ Released `v1.5.0`, `v2.4.0` (2026-10-17) | Oct 2026 |
| 10 | **backend 1.6.0 + web 2.5.0** | Custom fields and custom kinds, defined per kind in Settings → Kinds & fields; pin, sort and filter on any field; built-in kinds become locked data (F-014, `api-v0.10.0`/`0.10.1`; fixes `v1.6.1`) | ✅ Released `v1.6.0`, `v2.5.0` (2026-10-19) | Oct 2026 |
| 11 | **backend 2.0.0 + web 2.6.0** | Settings rework; "kind" becomes "type"; lists can have no type; price follows the type definition (F-015, `api-v0.11.0`, breaking) | ✅ Released `v2.0.0`/`v2.0.1`, `v2.6.0` (2026-10-19) | Oct 2026 |
| 12 | **backend 2.4.0 + web 2.13.1** | **Books type** with lookup (Open Library + Hardcover), store and streaming links, up to 3 pins (F-016, `api-v0.12.0` to `0.15.0`, many follow-ups) | ✅ Done (2026-10-19/20) | Oct 2026 |
| 13 | backend 2.5.0 + web 2.14.0 | **Type refactor** (F-018): five plural built-ins, no-type list glyph, icon editing from the header and sidebar | ✅ Done (2026-10-20) | Oct 2026 |
| 14 | backend 2.6.0 | **Backend architecture refactor** (F-019): layers (handler → service → repository), simple queries, soft deletes, one baseline migration, code-first generated OpenAPI (`api-v1.0.0`) | ✅ Done (2026-10-31, backend 2.6.0, `api-v1.0.0`/`api-v1.0.1`) | Oct–Nov 2026 |
| 15 | web 2.18.0 | **Web architecture refactor** (F-020): feature slices with lint-enforced boundaries, big files split, one data layer, link building moves from the backend to the web | ✅ Done (2026-10-31, web 2.18.1) | Oct–Nov 2026 |
| 16 | web | **Icon audit and fix** (F-017): every link, store and streaming icon correct; per-icon official SVGs (no single pack covers all, checked), one registry, one tile size | ✅ Done (2026-10-30, web 2.19.0 and 2.19.1) | Oct 2026 |
| 17 | web 2.20.0 | **Web restyle "Editorial"** (F-021): new tokens, type scale and self-hosted fonts across every screen, no behaviour change | ✅ Done (2026-10-30, web 2.20.0, web#96, D-111) | Oct 2026 |
| 18 | **backend 2.7.0 + web 2.21.0** | **Simplify and my services** (F-022): custom types and pin settings removed, owned streaming services in Settings, missing icons and white tiles | ✅ Done (backend 2.7.0 `api-v2.0.0` backend#66; web 2.21.0 web#103; D-112, D-113) | Nov 2026 |
| 19 | **backend 2.8.0 + web 2.22.0** | **No custom fields** (F-023): Settings "Types & fields" and custom fields removed; types are code; backend treated as not yet started (one baseline schema, no migrations) | ✅ Done (backend 2.8.0 backend#67; web 2.22.0 web#105; D-114, D-115) | Nov 2026 |
| 20 | **deploy + backend 2.8.1–2.8.3 + web 2.22.1–2.22.2** | **Raspberry Pi prod** (F-024): Pi 3B+ on the LAN, GHCR arm64 images, per-repo GitHub Releases as prod approval, one-minute release check, migrations in the api image, preflight on a DB copy and health-gated rollback (D-116 to D-118) | ✅ Live 2026-11-03 | Nov 2026 |
| 21 | deploy | **Off-Pi backups to Google Drive** (rclone, encrypted, token authorised on the Mac) | ✅ Done 2026-11-04 (rclone crypt, nightly upload, 30 kept) | Nov 2026 |
| 22 | deploy | **Test stack on the Pi**: GitHub pre-releases deploy to a separate, empty test stack on port 8081 (`./deploy/pitest`); prod keeps the release marked latest (D-119) | ✅ Done 2026-11-04 (live on 8081) | Nov 2026 |
| 23 | web | **Mobile fixes** (F-025): no zoom on focus, one-row list toolbar, compact header, sidebar padding, long press for Move/Delete with drag reorder kept, smaller link icons, drop the manual-sorting hint | ✅ Done 2026-11-05 (web 2.23.0–2.28.1, backend 2.8.4–2.10.0) | Nov 2026 |
| 23b | backend + web | **List polish, availability filters, unique titles** (F-026) | ✅ Done 2026-11-05 (backend 2.11.0–2.11.2, web 2.29.0, D-126, D-127) | Nov 2026 |
| 24 | deploy | **Alerts via healthchecks.io**: failed deploy or rollback, failed or stale backup, release check stuck, disk or memory low, prod container unhealthy, Pi offline | ✅ Done 2026-11-05 | Nov 2026 |
| 25 | deploy + backend | **Hosted logs and latency charts** (light agent shipping to a free hosted dashboard; lifts the "no metrics" rule) | ✅ Done 2026-11-05 (D-128) | Nov 2026 |
| 26 | local doc | **Pi operations guide** (kept only on your machine, not in git): full setup from an empty SD card, how the repos sit on the Pi, push vs release, where the logs are, runbooks for failures, re-setup from scratch, restore from Google Drive | ✅ Done 2026-11-06 (~/Desktop/Collections Pi Guide) | Nov 2026 |
| 27 | backend + web | **Chores and home-screen app**: deploy docs rewritten, image pruning after deploys, tmdb client split, default name "Collections" (backend 2.11.3), iPhone home-screen web app with manifest and icons (web 2.30.0) | ✅ Done 2026-11-06 (D-131) | Nov 2026 |
| 28 | backend + web | **Fixes round (phone feedback)**: clickable links with site favicons in expanded items and on the item row, "Validation failed" on Fantasia titles, Markdown edit buttons under the box + reliable copy/paste on iOS, website link ellipsis, list icon picker (no emoji preview, color next to icon), no description collapse, blurred top in the home-screen app, localized book authors (+ refresh feasibility) | ✅ Done (backend done: 2.12.0 / api-v3.3.0, backend#84; authors not localizable, D-132; web 2.32.0–2.39.0 done, web#126–#133, D-133..D-143; new-item keyboard confirmed fixed on the iPhone 2026-11-07) | Nov 2026 |
| 29 | ops (you) | **Move the Pi to another room**: moved and switched from Wi-Fi to Ethernet (192.168.1.75 on eth0, Wi-Fi off on the Pi); Pi guide updated | ✅ Done 2026-11-07 | Nov 2026 |
| 30 | deploy + web | **Remote access**: Cloudflare Tunnel (`cloudflared` on the Pi, `tunnel` profile + `TUNNEL_TOKEN`) + Cloudflare Access on `collections.federama.dev` (allowed emails, Google login + one-time PIN, Bypass only for the icon files); federama.dev DNS on Cloudflare (GitHub Pages records kept); manifest `use-credentials` (web 2.40.0, D-144). Domain transfer to Cloudflare tracked in To-do | ✅ Done 2026-11-09 | Nov 2026 |
| 31 | backend + web | **Accounts via Cloudflare Access** ([F-027](design-docs/features/F-027-accounts.md), brief 2026-11-09; LAN: always the owner, D-150): the backend reads the user from Access's signed token (`Cf-Access-Jwt-Assertion`, verified against the team keys + app audience, never the plain header), no passwords or login screens in the app; `collections.federama.dev` goes through Access; the home network (`raspberrypi.local`, no Cloudflare headers) always acts as the owner (`OWNER_EMAIL`), no switch and no redirect (D-150); dev/test use fake identities; then users, list ownership and sharing (backend 3.0). Brief to write after 30 | ✅ Done 2026-11-11: backend 3.0.0 (`010f44b`, `api-v4.1.0`, D-147/D-148/D-152) + web 3.0.0 (`89cf732`, D-149/D-151), rehearsed on the Pi test stack with the pre-accounts snapshot, live on prod; LAN = owner (D-150) | Nov 2026 |
| 33 | web | **Web 3.1.0 fixes**: drag and drop of lists/folders into and out of folders doesn't work on prod (3.0.0); lists inside a folder indented a bit more in the sidebar | ✅ Done 2026-11-11: web 3.1.0 (`789708a`, web#148, D-153), confirmed on prod; test stack always on after a lone-web 502 on the Pi test stack (D-154) | Nov 2026 |
| 34 | web + deploy | **Privacy policy inside the app**: public page `collections.federama.dev/privacy` (no login: its own Cloudflare Access Bypass app, like the icons; also at `raspberrypi.local/privacy`), self-contained static page served by the web container, same content as today's `federama.dev/privacy`; the web orchestrator releases 3.2.0 itself (pre-release → test stack → latest); then the two Google apps' Branding points to it and the website page is removed (no redirect, no link: federama.dev stays unrelated to Collections). Home page stays `https://federama.dev` (Google wants a public one; the app is behind login) | ✅ Done 2026-11-11: web 3.2.0 (D-155) live, Access bypass `Collections privacy`, both Google apps' Branding → `https://collections.federama.dev/privacy`, page removed from federama.dev (404, no link) | Nov 2026 |
| 35 | backend + web | **Sidebar drag and drop, anywhere** (reported 2026-11-15 on prod 3.2.0): a list/folder drops into a folder only over the folder's name, and leaves a folder only at the very bottom of the tree. Wanted: drop anywhere (between any rows, inside an open folder at any position, back out between top-level rows) and it lands exactly where it was dropped, with a clear insertion indicator. Backend first: an atomic position on the move endpoints (today they only append last) | ✅ Done 2026-11-15: backend 3.1.0 (`before_id` on move, `api-v4.2.0`, D-159) + web 3.3.0 (drop anywhere, D-158, web#150), test stack then prod | Nov 2026 |
| 36 | web | **Movie list extras** (asked 2026-11-15): in a Movies list's `…` menu, (1) open https://mikeyguinness.com/movies/ in a new tab, (2) pick a random movie from the list | ✅ Done 2026-11-15: web 3.4.0 (D-160, web#151): "Movie Vector Map" link + random pick, test stack then prod | Nov 2026 |
| 37 | web | **Upkeep**: Node 26 LTS (D-042), TypeScript 7 if typescript-eslint supports it (D-040), the flaky drag-reorder e2e, dependency bumps + audit | ✅ web 3.5.0 merged and released 2026-11-15 (D-161; also instant Settings) | Nov 2026 |
| 38 | backend + web | **Synopsis, rating, genres** ([F-028](design-docs/features/F-028-synopsis-rating-genres.md), brief 2026-11-16): the provider's summary fills an empty item description (movies, TV, books; metadata language, English fallback; tracked until you edit it), the TMDB score for movies/TV (sortable, shown only in the expanded item), TMDB genres (filterable, chips in the expanded item); existing items via a one-off backfill. Backend first | ✅ Done 2026-11-16: backend 3.2.0 (`api-v4.3.0`) + web 3.6.0 released, prod (D-162–D-165) | Nov 2026 |
| 39 | web | **All items always shown** (reported 2026-11-16): a list over 200 items (Film, 207) ends with "Load more (7 of 7 remaining)"; every list must show all its items, with sort, filters, drag reorder and the random pick working on the whole list | ✅ Done 2026-11-16: web 3.6.1 released, prod (D-166, web#155) | Nov 2026 |
| — | future | Wanted, not scheduled (§3): new high-endurance SD card (32–64 GB Samsung PRO Endurance / SanDisk MAX Endurance; steps in the Pi guide, 04), installed from scratch as the full backup drill (fresh OS following the Pi guide 02, secrets from 1Password, data from Drive per 03; the old card stays as the fallback), new power supply (under-voltage confirmed 2026-11-12; see §3) | 🔭 Future | — |

---

## 3. Future (wanted, not scheduled)

| Idea | Notes |
|---|---|
| New SD card | 32–64 GB high-endurance (Samsung PRO Endurance / SanDisk MAX Endurance), installed from scratch as the full backup drill: fresh OS per the Pi guide 02, secrets from 1Password, data from Drive per 03; the old card stays as the fallback |
| New power supply | Under-voltage confirmed 2026-11-12 (`vcgencmd get_throttled` = `0x50000`, 1669 warnings since boot, flapping every ~15 s even idle), so the red light isn't steady. Buy the official Raspberry Pi micro-USB 5.1 V 2.5 A supply (or a 5 V 3 A Pi-specific one with an attached cable); swap with `sudo shutdown -h now`; after: `vcgencmd get_throttled` = `0x0` and `journalctl -k -b \| grep -ci voltage` = `0`. Do it before or with the SD card swap |

## 4. Exploring and not on the roadmap

**Exploring (a possible new concept, not sure yet):**
| Idea | Notes |
|---|---|
| Compare & AI assist | A separate, future concept: side-by-side comparison of 2–4 items, with AI help (drafts, comparisons, Q&A) only with explicit approval before anything is saved. To be defined from scratch, if ever |

**Not on the roadmap for now:**
- **Mobile app.** Only after accounts and once the app is public; same pinned OpenAPI contract, separate repo.
- **Multiple images per item.**
- Offline mode, rich-text editor, version diffs, custom workflows (deferred since the MVP, no demand).

## 5. Open questions
| ID | Question | Default |
|---|---|---|
| Q-4 | License for the repos? | No LICENSE (all rights reserved) |

---

## How this roadmap is maintained
- The **top-level orchestrator** (a session in this parent repo) owns this file. It turns a bigger initiative into a feature
  brief in `design-docs/features/F-NNN-*.md` with user stories per repo, once you approve it.
- The **repo orchestrators** split stories into tasks and run them with internal worker agents
  ([`design-docs/AGENT_WORKFLOW.md`](design-docs/AGENT_WORKFLOW.md) §1b). Progress is tracked in [`design-docs/STATUS.md`](design-docs/STATUS.md).
- This file is updated when something starts, ships, or changes horizon; the repo orchestrators update their own row after merging. Detailed task history stays in STATUS.md, manual ops chores in the local Pi guide.

## Changelog
- 2026-11-16: **Roadmap 39 done**: every list shows all its items (web 3.6.1, no more Load more past 200).
- 2026-11-16: **Roadmap 38 done**: synopsis, TMDB score and genres (F-028) live with backend 3.2.0 and web 3.6.0; the one-off backfill fills existing items in the background.
- 2026-11-15: **Roadmap trimmed**: the October timeline, Now/Next/Pool, shipped-MVP and Next sections removed (all done; the history stays in §2, the feature briefs and this changelog), the done manual chores list removed (Google apps published, domain transfer + DNSSEC, Access allow list, old backups deleted, restore drill on the test stack: all 2026-11-11/15; details in the local Pi guide). Upkeep becomes row 37; the rest of the old upkeep list (VoiceOver pass, mock-mode check, upload checks, icon packs, exposure script) dropped.
- 2026-11-15: **Advanced search dropped**, "Not doing" list removed (your call); the to-do row is gone: new SD card and power supply are both in Future.
- 2026-11-15: **List import dropped** (your call). Roadmap 36 added: Movies list menu extras.
- 2026-11-11: **Collaborative Markdown dropped** (D-157): pool item 9 removed, the ARCHITECTURE/DATA_MODEL real-time seams retired.
- 2026-11-11: **Public API dropped** (D-156): pool item 7 removed, PRODUCT §13 Phase 4 dropped; home scripts already work (LAN = owner), a remote client would use an Access service token.
- 2026-11-01: **App in use (D-116):** baseline frozen as migration 1.0; one migration per feature, edited in place until released; dev/test vs prod, prod releases only after your yes in chat. Next: accounts (migration 1.1).
- 2026-11-01: **F-023 backend done** (backend 2.8.0, backend#67, `api-v3.0.0`, D-114; 2.x because 3.0.0 is reserved for accounts): custom fields, the five field operations and the `type_definitions`/`type_fields` tables removed; built-in types are code; `GET /types` kept from the registry. Baseline schema edited in place: reset dev and test DBs. Next: F-023 W1. TMDB check: the Apple subscription is now named "Apple TV" (id 350), the store "Apple TV Store" (id 2); "Amazon Prime Video with Ads" (id 2100) and the "… Amazon Channel" entries do not resolve in the web registry yet (web follow-up).
- 2026-11-01: **F-023 web done** (web 2.22.0, web#105, pointer `d37ecf4`, D-115): Settings "Types & fields" and custom-field UI removed, sort/filter on built-in fields only, code adapted to `api-v3.0.0`; type definitions still read from `GET /types` (cached for the session), so `listTypes` stays. Also TMDB "Amazon Prime Video Free with Ads" (613) → Prime Video. F-023 complete.
- 2026-10-16: **F-009 merged** (backend 1.3.0 / api-v0.7.0 tagged; web#37 squashed `80a40bb` incl. F-010 new-list folder and F-011 review fixes). Web 2.2.0 bumped (web#39, audit clean); tag v2.2.0 pending.
- 2026-10-19: **Before the pool, three items added by you:** (1) Books type with automatic lookup (F-016, briefed), (2) icon audit and fix (F-017), (3) type refactor (F-018, to be defined). Order: F-016, then F-017, then F-018.
- 2026-11-01: **F-022 web done** (web 2.21.0, web#103, pointer `9ddce37`): custom-type UI and Pinned control removed (fixed pins per type in the web), "My streaming services" in Settings > Media filters item and row streaming (empty = all), Apple TV Store / Amazon Video reuse the Apple TV+ / Prime Video marks, Chili added, every inset mark on a white tile. F-022 complete. Open: check TMDB's live name for the Apple store ("Apple TV" vs "Apple TV Store").
- 2026-11-01: **F-022 backend done** (backend 2.7.0, backend#66, `api-v2.0.0`, D-112): custom types and pinned-field config removed, `owned_streaming_services` in settings. Baseline migration edited in place: reset dev DBs. Next: F-022 web.
- 2026-10-30: **F-021 web restyle "Editorial" done** (web 2.20.0, web#96, D-111). Next: the pool (accounts → security review → collaborative Markdown).
- 2026-10-30: **Collaborative Markdown moved after the security review** (you, 2026-10-30): pool is now accounts → security review/exposure → collaborative Markdown. **Frontend restyling** is next, chosen with the web orchestrator.
- 2026-10-30: F-017 follow-up shipped as web 2.19.1 (D-110 display order); flaky drag-reorder e2e added to Upkeep.
- 2026-10-30: **F-017 done** (web 2.19.0, web#94, D-109): 34 SVG icons behind one registry, picker 7 → 19 services; Amazon and Apple Books from Wikimedia Commons, brand rasters embedded as SVG wrappers. Next: the pool (collaborative Markdown → accounts → security review).
- 2026-10-30: dev DB reset on the new baseline. **F-017 icons planned:** Simple Icons lacks Amazon, Prime Video, Disney+, Kobo, Bookshop.org, Open Library, Apple Books, TIMvision, Infinity, RaiPlay and others, so icons are sourced as per-icon SVGs (official sources first) behind one registry.
- 2026-10-31: **F-019 and F-020 done** (D-108): backend 2.6.0 with a generated contract `api-v1.0.0`/`1.0.1`, layers and one baseline migration; web 2.18.1 with feature slices and the links moved to the web. Housekeeping done 2026-10-30. Next: F-017 icon audit, then the pool (collaborative Markdown → accounts → security review).
- 2026-10-21: F-018 done. **Architecture refactor added before the icon work (F-017):** F-019 backend (layers/DAO, simple queries, soft deletes, one baseline migration, code-first OpenAPI `api-v1.0.0`) and F-020 web (feature slices, big files split, one data layer, link building moves to the web). Prod unused, so no compatibility; behaviour preserved, e2e unchanged.
- 2026-10-20: F-016 done (many follow-ups, backend 2.4.0 / `api-v0.15.0`, web 2.13.1). **F-018 type refactor planned and moved before F-017** (icons), at your request: five plural built-ins, camera removed, motorcycle + car → Vehicles, no-type list icon, icon edit moved.
- 2026-10-19: **F-015 done** (your changes: Settings rework, kind → type, lists without a type; backend 2.0.0/2.0.1, web 2.6.0, `api-v0.11.0`). D-094 records it; accounts become backend 3.0 / web 3.0.
- 2026-10-19: **F-014 done** (custom fields + custom kinds; backend 1.6.0/1.6.1, web 2.5.0, `api-v0.10.1`); pool item 5 shipped. The pool is up for a re-plan before the next item.
- 2026-10-17: **F-012 and F-013 done** (backend 1.4.0/1.5.0, web 2.3.0/2.4.0, `api-v0.8.0`/`api-v0.9.0`); pool items 3 and 4 shipped. Next: pool item 5, custom fields + types. Worker tiers are AI agnostic (D-087). Web `v2.2.0` was never tagged (2.3.0 followed it).
- 2026-10-16: **F-008 done**; **F-009 UI polish 2** added as Next (web 2.2.0, backend 1.3.0, api-v0.7.0). Icon packs added to Upkeep.
- 2026-10-15: **F-008 UI polish** added as Next (web 2.1.0, backend 1.2.2), before pool item 3.
- 2026-10-15: **F-005 done**: backend `v1.2.1` (metadata stripped from uploads + `strip-images` backfill), nightly backup timer, `backup-status`, audits before tags. Next: pool item 3, list icons + F-004 product gaps.
- 2026-10-15: backend tagged `v1.2.0` (F-002 backend features), parent `v2.0.0` message names both versions. Pool items 1–2 merged into **F-005 ops hardening** (Now): EXIF strip, scheduled backups + `backup-status`, audits before tags; no CI or Dependabot (D-084); remaining upkeep done as chores when due.
- 2026-10-15: **web 2.0.0 released** (F-002 Frosted Gallery, in-place editing; backend contract `api-v0.5.0`, parent tag `v2.0.0`). D-083 records the web interaction rules. Next: pool item 1.
- 2026-10-15: **v1.1.0 released** (parent + web tags; backend tagged earlier). **F-003 done** (backend#19 `make smoke`, web#29 Playwright). F-002 UI rework is Now, in a sister session (design first).
- 2026-10-15: **Pool order set by you:** UI refresh → CI & upkeep → ops hardening → list icons + gaps → TMDB + auto images → user-defined kinds → collaborative Markdown → accounts → security review. List import moves to Future. F-002 gets the inputs collected so far (no edit mode, edit in the item side page) and is run from a sister session.
- 2026-10-15: **Pool re-shaped.** Proposed order: CI & upkeep → ops hardening → list icons + gaps → TMDB + auto images → list import → user-defined kinds → collaborative Markdown → accounts (backend 3.0) → security review & hardening, which gates internet exposure and the public API. Advanced search is Future. Compare + AI assist becomes one uncertain future concept. Mobile app and multiple images per item are off the roadmap for now.
- 2026-10-15: **F-007 merged** (1.1.0, `api-v0.3.0`); PRODUCT and DATA_MODEL updated. **F-003 approved and Now**: `make smoke` + ~8 Playwright specs, lean workflow (D-081).
- 2026-10-15: **Exploration done, F-007 approved** (1.1.0, Now): restructure + 6 UI fixes, one-off lean workflow (D-079). Versions diverge after 1.1.0: UI refresh = web 2.0.0, TMDB stays backend 1.x, accounts = backend 2.0 (D-080). Pool gains list icons and automatic image lookup; F-002 gains inline editing and drag-from-anywhere; user-defined kinds in Exploring.
- 2026-10-15: **v1.0.1 released** (F-006 polish); the exploration session starts. Backup drill (U1) moved to F-005.
- 2026-10-15: **Re-plan.** Next is now, in order: exploration session → F-007 lists and items restructure (1.1) → brief e2e (F-003, cut to e2e only) → UI refresh (F-002, 1.2). List import added. F-004, F-005, CI and upkeep, 2.0 and 3.0 move to a pool ordered after 1.2 (D-078).
- 2026-10-15: **v1.0.0 released.** Workflow v2 started. F-006 (1.0.1 polish) is Now; F-001 done.
- 2026-10-15: Q-04 done. F-002 made generic: the design comes from you later (D-075). The v2 workflow starts after Q-05 + C4.
- 2026-10-15: Roadmap created. 1.0 feature-complete; F-001 to F-005 defined; UI refresh (F-002) added.
