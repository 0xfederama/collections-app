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
5. **Ownership:** every **top-level** folder and top-level list has an owner (`owner_user_id`). Anything inside a
   folder belongs to that folder's owner. Each user sees: what they own + top-level folders shared with them.
6. **Sharing:** only **top-level folders**, only with **edit** rights (no view-only). Shared from the folder's `…` menu
   in the sidebar, which holds every share setting (share with…, who it's shared with, stop sharing; for the
   recipient: leave). A shared folder shows a small **two-person badge** at the bottom right of its icon, for both users.
7. The recipient sees a shared folder **at their top level** and can't move it into their own folders. **Ordering of
   top-level entries is per user.**
8. **Moving:** dragging one of your lists into a shared folder makes it shared. Moving anything **out of** a shared
   folder is allowed **only for the folder owner**; the other person then no longer sees it.
9. **Trash:** deleting inside a shared folder goes to the owner's trash, and **both** users can see and restore that
   folder's deleted things.
10. **Stopping a share:** the folder disappears for the other person; everything they added stays (it's the owner's).
    The recipient can also leave a share. **No ownership transfer** for now.
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
- B3 **Shares**: share/unshare/leave endpoints for top-level folders, list of shares, `shared` flag + people on folder
  payloads; move rules (decision 8), trash visibility (decision 9).
- B4 **Who changed**: created/updated by on payloads, description history author.
- B5 **Workspace name gone**: drop it from the API and settings (keep the table).
- B6 **Authorization tests**: for every endpoint, user A can't read or change user B's private data; recipient rights
  inside a shared folder; LAN fallback off/on; forged plain email header ignored.

Web (after the contract):
- W1 Identity: `GET /me`, avatar + name in Settings / menu, logout link, 401 → reload (Access login).
- W2 "Collections" everywhere as the title; remove the workspace-name setting.
- W3 Sharing UI in the folder's `…` menu in the sidebar (share with a known user by email, list, stop sharing, leave).
- W4 Two-person badge on shared folder icons (sidebar, Home, phone).
- W5 Move/trash rules surfaced (recipient can't move out; trash of shared folders for both).
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

## Out of scope
Per-user settings, Settings → Account editing, ownership transfer, view-only shares, sharing lists or nested folders,
removing workspaces, a public API.

## Log
- 2026-11-09: brief written after exploring the feature with the user (decisions 1–15).
