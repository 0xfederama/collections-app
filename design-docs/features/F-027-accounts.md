# F-027 — Accounts via Cloudflare Access, shared folders (roadmap 31)

Status: brief (2026-11-09). Repos: backend (first, contract), frontend-web. Workflow v2. Backend major: **3.0.0**.

Critical feature: prod data is real. **No orchestrator publishes a GitHub release** (not even a pre-release): the user
or the top-level orchestrator does, after the rehearsal below. Orchestrators stop at "PR merged + pointer bumped".

## Why
Two people use the app. Each needs their own lists, plus folders they share. Login already exists in front of the app
(Cloudflare Access, roadmap 30, D-146), so the app gets accounts without passwords, sign-up or sessions of its own.

## Decisions (user, 2026-11-09)
1. **Identity = Cloudflare Access.** The backend reads the user from the `Cf-Access-Jwt-Assertion` header and **verifies
   it** (signature against the team's public keys `https://<team>.cloudflareaccess.com/cdn-cgi/access/certs`, cached;
   `aud` = the Access application's audience tag; `iss`; expiry). The plain `Cf-Access-Authenticated-User-Email`
   header is never trusted alone. Config: `ACCESS_TEAM_DOMAIN`, `ACCESS_AUD`. No passwords, no login screens, no
   sessions in the app; logout links to `/cdn-cgi/access/logout`.
2. **Accounts are created on first login** (Access already decides who gets in). Name and avatar come from the Google
   identity when present (Access identity endpoint `/cdn-cgi/access/get-identity` or the JWT claims), else the email.
   No Settings → Account editing for now.
3. **The visible app name is always "Collections"** (top bar, phone Home, title). The workspace-name setting and its
   UI go away; `WORKSPACE_NAME` is no longer needed.
4. **Keep the single workspace under the hood** (top-level decision, see "Workspaces" below): it becomes the instance
   that holds the shared settings. Users, ownership and shares are added on top.
5. **Folders and lists are boxes** (user, 2026-11-11). Ownership lives **only on top-level entries**
   (`owner_user_id` on top-level folders and lists); anything inside a folder inherits access from its top-level
   ancestor. One owner per top-level entry plus a **members** table for shares (not multiple owners): simplest, and
   expandable later (roles, view-only, transfer) without changing the model. Each user sees what they own plus the
   top-level folders shared with them. Whoever creates a folder or list owns it.
6. **Sharing:** only **top-level folders**, only with **edit** rights (no view-only). Shared from the folder's `…` menu
   in the sidebar, which holds every share setting (share with…, who it's shared with, stop sharing; for the
   recipient: leave). A shared folder shows a small **two-person badge** at the bottom right of its icon, for both users.
7. The recipient sees a shared folder **at their top level** and can't move it into their own folders. **Ordering of
   top-level entries is per user.**
8. **Moving (boxes):** moving a list or folder into a shared folder makes it shared (it loses its own owner and
   inherits the shared folder's access). **Any member** of a shared folder may move things out of it: moved to the
   mover's own top level (or into one of the mover's private folders), it becomes **the mover's**, and the others no
   longer see it. Only top-level folders can be shared/unshared; a folder inside a shared folder is shared through
   its parent.
9. **Trash:** deleting inside a shared folder goes to the owner's trash, and **both** users can see and restore that
   folder's deleted things.
10. **Stopping a share** (owner only): the folder disappears for the other person; everything they added stays
    (it's the owner's). The recipient can also leave a share. **No explicit ownership transfer** for now (moving a
    box out of a shared folder is the only way ownership changes, decision 8).
11. **Settings stay shared** by everyone (country for store links, types/kinds, custom fields, streaming services):
    they stay on the workspace. May become per-user later.
12. **Who changed what:** record the user on every change (created by / updated by on folders, lists, items;
    description history entries). Shown as "Updated by …" and in the description history.
13. **Search** covers own + shared lists; **Quick add** offers every list the user can edit.
14. **LAN / environments** (roadmap 31, D-146): `raspberrypi.local` redirects to `collections.federama.dev`. Emergency
    switch `LAN_OWNER_FALLBACK=true` serves LAN requests (no Access token) as `OWNER_EMAIL`; off by default.
    Dev and the test stacks use fake identities: a fixed set of dev users and a **user switcher shown only in
    dev/test** (never compiled into or enabled in prod), so sharing can be tested.
15. **Data rules (IMPORTANT, user):** migrations change **structure only**. The only data they may touch is a generic
    **backfill**: every existing row gets the owner user (created from `OWNER_EMAIL` if missing). **No migration names
    specific data** (no `WHERE name = 'Noi2'`, no user emails, no folder ids). A fresh install with an empty database
    must come up with the same migrations and no manual step. Everything specific to the user's data is done by the
    user in the UI after the release:
    - move the lists inside folder "Fede" to the top level, delete the empty folder;
    - when the second person has logged in once, share folder "Noi2" with them.

## Workspaces (top-level analysis, 2026-11-09)
The user asked whether to drop workspaces. Today every domain table carries `workspace_id` with composite FKs
(about 750 references in 60 backend files). Dropping it means rewriting every table, query and test in the same
release that adds accounts, for no visible gain: with one workspace the column is a constant, and decision 11 (shared
settings) needs exactly such an instance-level home. **Keep it, hidden.** Removing it can be a separate refactor later.

## Stories
Backend (contract first, one PR per story, `api-v4.0.0`):
- B1 **Identity**: Access JWT verification middleware (keys cached + refreshed, `aud`/`iss`/`exp`), `users` table, create on
  first request, `GET /me` (id, email, name, avatar). `LAN_OWNER_FALLBACK` + `OWNER_EMAIL`. Dev/test identity provider
  (header or cookie set by the dev switcher, enabled only by an explicit dev/test config flag; prod refuses to start
  with it on). 401 for every request without a valid identity.
- B2 **Ownership + backfill**: `owner_user_id` on top-level folders and lists, created/updated-by columns, migration
  with the generic backfill to the owner user (decision 15). Every read and write filtered by "visible to the
  current user"; per-user ordering of top-level entries.
- B3 **Shares**: members table, share/unshare/leave endpoints for top-level folders, `shared` flag + members on folder
  payloads; move rules (decision 8: into shared = loses own owner, out = mover becomes owner), trash visibility (decision 9).
- B4 **Who changed**: created/updated by on payloads, description history author.
- B5 **Workspace name gone**: drop it from the API and settings (keep the table).
- B6 **Authorization tests**: for every endpoint, user A can't read or change user B's private data; recipient rights
  inside a shared folder; LAN fallback off/on; forged plain email header ignored.

Web (after the contract):
- W1 Identity: `GET /me`, avatar + name in Settings / menu, logout link, 401 → reload (Access login).
- W2 "Collections" everywhere as the title; remove the workspace-name setting.
- W3 Sharing UI in the folder's `…` menu in the sidebar (share with a known user by email, list, stop sharing, leave).
- W4 Two-person badge on shared folder icons (sidebar, Home, phone).
- W5 Move/trash rules surfaced (moving out of a shared folder makes it yours, with a confirmation that the others lose
  it; trash of shared folders for both).
- W6 "Updated by" and description history authors.
- W7 Dev/test user switcher (dev/test builds only).
- W8 LAN redirect in the web image's Caddy: requests whose **Host** is not the public hostname (`raspberrypi.local`,
  the LAN IP) get a redirect to `PUBLIC_URL` (same path), unless `LAN_OWNER_FALLBACK=true`; off when `PUBLIC_URL` is
  unset (dev, test stacks). Host-based, not token-based: the Access Bypass paths (icons) arrive without a token.

Deploy (top-level orchestrator): `.env.example` (`ACCESS_TEAM_DOMAIN`, `ACCESS_AUD`, `OWNER_EMAIL`,
`LAN_OWNER_FALLBACK`, `PUBLIC_URL`) passed to `api` and `web` in compose, README and Pi guide.

## Safety plan (top-level orchestrator + user)
1. **Freeze**: the user doesn't change data until this is live.
2. **Snapshot** before anything: `./deploy/prod snapshot pre-accounts` (named, verified, never pruned, Drive copy in
   `collections-snapshots`). Note the current versions (`cat deploy/server/versions.env`).
3. **Rehearsal on the Pi test stack**: `./deploy/pitest restore <snapshot> --force`, publish the new versions as
   **pre-releases** (test stack only), check the user's real data there: everything owned by the owner, folders
   intact, sharing between two dev identities.
4. **Prod**: publish as latest only after the rehearsal passes.
5. **Rollback**: mark the previous releases (noted in step 2) as latest again, wait for the deploy, then
   `./deploy/prod restore <snapshot> --force`.

**Rollback point (2026-11-11):** snapshot `/srv/collection/snapshots/pre-accounts/20261111T133944Z` (verified: 10
tables, 7 content bodies, 317 attachments; Drive copy `gdrive-crypt:collections-snapshots/pre-accounts/20261111T133944Z`),
taken on **backend 2.12.0 + web 2.41.0**. Rollback = mark backend `v2.12.0` and web `v2.41.0` as latest, wait for the
deploy, then `./deploy/prod restore /srv/collection/snapshots/pre-accounts/20261111T133944Z --force`.

## Repo breakdown: backend (backend orch., 2026-11-11; design = D-147)
One PR per story, in order, on branches `feature/f027-b<N>-<slug>`; one migration `000002_accounts` created in B1 and
edited in place by B2–B4 until released (D-116). Workers: complex tier (Sonnet 5.5) for B1–B3 and B6 (security,
schema, concurrency), simple tier for B4–B5. Contract tag `api-v4.0.0` once B5 merges (B6 adds tests only); backend
`3.0.0` after B6. No GitHub release by the orchestrator.

**Identity (B1).** Order per request on `/api/v1/*` (probes and `/admin` exempt): (1) `Cf-Access-Jwt-Assertion`
present → verify (go-oidc v3 verifier over our own throttled JWKS cache: refetch on unknown `kid` at most once a
minute, so forged tokens cannot hammer Cloudflare; `iss` = `https://<ACCESS_TEAM_DOMAIN>`, `aud` = `ACCESS_AUD`,
`exp`/`nbf`, `email` required) → invalid = 401, never a fallback; (2) else dev identity when `DEV_IDENTITY=true`
(header `X-Dev-User` or cookie `dev_user`, one of the dev identities; absent → the first); (3) else LAN fallback when
`LAN_OWNER_FALLBACK=true` **and** the request carries no Cloudflare edge header (`Cf-Ray`, `Cf-Connecting-Ip`) → the
owner; (4) else 401 `unauthenticated`. `Cf-Access-Authenticated-User-Email` is never read. Users are keyed by
lower-cased email, created on first request; name/avatar best-effort from the team `get-identity` endpoint
(cookie `CF_Authorization=<token>`, 3 s timeout, at creation and at most daily; https avatars only), else null (web
shows the email). Config: `APP_ENV=production` requires `ACCESS_TEAM_DOMAIN` + `ACCESS_AUD` and refuses
`DEV_IDENTITY=true`; `LAN_OWNER_FALLBACK=true` requires `OWNER_EMAIL`. Dev identities: `OWNER_EMAIL` (or
`owner@dev.test`), `alice@dev.test`, `bob@dev.test`. The Pi test stack must run `APP_ENV=development` to use them.
**Ownership (B2).** `owner_user_id` only on top-level folders/lists (null when nested); access to anything is decided by
its top-level ancestor (the "box"): visible = owner is me, or (B3) the box is a folder shared with me. One `access`
feature resolves boxes over a per-request snapshot (folders + lists in any state, the caller's memberships). Enforcement:
(a) one Huma middleware maps every `{id}`/`{batch_id}` path (folder, list, item, attachment, trash batch) to its box and
answers 404 when not visible, before If-Match; (b) services check body references (create parent, move/restore
destination, reorder parent, item move list) through a consumer interface, outside `InTx`; (c) tree, search, recent
items and trash list are filtered to visible boxes. Moves: top-level → into a folder clears the owner; nested → top
level sets the owner to the mover; same for restore with a destination; restore in place keeps the stored owner.
Per-user order of top-level entries in `user_top_order` (fallback: the row's `sort_order`). Backfill (decision 15):
at API startup, under the bootstrap lock, ownerless top-level folders/lists (any state) get the user of `OWNER_EMAIL`
(created if missing); if such rows exist and `OWNER_EMAIL` is unset the API refuses to start. The SQL migration is
structure only. Attribution columns are not backfilled (unknown authors stay null).
**Shares (B3).** `folder_members` (top-level folders only). `POST /folders/{id}/members {email}` (owner; email of a
user who signed in once; 200 Folder), `DELETE /folders/{id}/members/{user_id}` (owner removes anyone, member removes
self = leave; 204); no If-Match, no version bump; under the tree lock. Folder payload: `owner_user_id`, `shared`,
`member_user_ids`; list payload: `owner_user_id`. Owner only (403 `forbidden`): delete/move a top-level shared
folder, share/unshare. A folder with members cannot move into a folder (409 `folder_shared`); sharing a nested
folder is 409 `folder_not_top_level`. Members may rename it and edit everything inside. Trash: a batch is visible
(list, restore, purge, empty) to whoever can see its root's box. Unsharing deletes the member's order row.
**Who changed (B4).** `created_by_user_id`/`updated_by_user_id` on folders, lists, items (null = unknown or system:
lookup refresh keeps the previous value); `author_user_id` on content versions; `GET /users` lists known users.
**B5** drops `workspace_name` (API, config `WORKSPACE_NAME`); the column stays. **B6** derives the endpoint list from
the spec and fails when an operation has no authorization test.
New link tables have no FK to folders/lists, so the 2.12.0 purge still works on the new schema (D-118); the new
purge deletes their rows explicitly.

## Out of scope
Per-user settings, Settings → Account editing, ownership transfer, view-only shares, sharing lists or nested folders,
removing workspaces, a public API.

## Log
- 2026-11-09: brief written after exploring the feature with the user (decisions 1–15).
- 2026-11-11: decisions 5, 8, 10 revised (user): folders and lists move like boxes; any member can move out of a shared
  folder and becomes the owner; one owner per top-level entry + members table. `deploy/prod snapshot` pushed.
- 2026-11-11: snapshot `pre-accounts` taken on prod (backend 2.12.0, web 2.41.0); data frozen until F-027 is live.
- 2026-11-11 (backend): design D-147; B1 identity merged (backend#85, `eaa2a4f`): Access JWT verification, dev identities, LAN fallback, `users`, `GET /me`, 401 `unauthenticated` everywhere. Deploy needs `ACCESS_TEAM_DOMAIN`/`ACCESS_AUD` in prod; Pi test stack `APP_ENV=development` for dev identities.
- 2026-11-11 (backend): B2 ownership merged (backend#86, `29787e6`): boxes, path guard (404), filtered tree/search/recent/trash, per-user top-level order, startup owner backfill; upgrade rehearsal `scripts/check-accounts-migration.sh` on a realistic 2.12.0 dataset: all row counts and 8/8 files unchanged, 6 top-level rows owned by the owner.
- 2026-11-11 (backend): B3 shares merged (backend#88, `071c853`): `folder_members`, share/unshare/leave endpoints, owner-only 403s, `folder_shared`/`folder_not_top_level`, in-tx visibility re-checks; item moves don't re-check in the tx (no ownership change). Restore of a top-level root to a new destination is owner-only.
