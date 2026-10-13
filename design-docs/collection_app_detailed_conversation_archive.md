# Collection App — Detailed Conversation Archive and Design-Handoff Context

**Created:** 2026-10-13
**Purpose:** Preserve the decisions, requirements, recommendations, caveats, and unresolved questions from the conversation so a new ChatGPT session can continue the work without losing important details.

> **Archive note:** This is a detailed, structured reconstruction of the conversation—not a byte-for-byte export of the original chat transcript. It preserves the substance of the user’s requests and the assistant’s recommendations, including technical details and roadmap distinctions. Where an exact original sentence is not available, the content is represented faithfully as a paraphrase. No design package, source code, OpenAPI document, SQL migration, or implementation has been created by this archive.

---

# Part I — Conversation history and decisions

## 1. Initial project idea and desired outcome

The user is building a personal/shared collection application for himself and his girlfriend. It should help them collect and organize things they like, want, may buy, or want to compare—for example movies, motorcycles, possible purchases, and other interests.

The user wants to eventually create a **complete design document and handoff package** that can be given to an orchestrator agent and its child agents. The package should be detailed enough that separate agents can implement the backend, frontend, integration, testing, and infrastructure without making incompatible assumptions.

The desired process is to first consolidate the project decisions, then generate the actual design and handoff documents. This archive is intended to be uploaded to a new ChatGPT session to continue that work.

## 2. Core product model

The initial product has one shared workspace for the user and his girlfriend.

The main organizational concepts are:

- **Workspace** — the top-level shared environment.
- **Folders** — can be nested.
- **Lists** — can exist at the workspace root or inside folders.
- **Items** — belong to exactly one list in the MVP.

Stable UUIDs should be used for workspaces, folders, lists, and items. Moving an item/list/folder must preserve its ID and content.

The app should support generic items as well as specialized item kinds such as movies and motorcycles. A generic item should only use common fields; specialized types can add their own metadata.

The app should stay lightweight and useful for organizing collections and making decisions. It is not intended to become a complicated project-management or workflow system.

## 3. Accounts, identity, and early deployment constraints

The MVP does **not** include accounts, authentication, or user identity. Do not invent a fake anonymous user model simply to simulate accounts.

The first run should initialize a workspace automatically.

A critical security constraint was agreed: **do not expose an unauthenticated writable API to the public internet**. The MVP can be used locally or over a trusted/private network, LAN, VPN, or private tunnel. Authentication and authorization must be added before any public exposure.

Accounts and access control are planned for the near future, but not in the MVP. They should be anticipated through clean boundaries where sensible, without prematurely implementing them.

A public API is even less settled. It must be explicitly reconsidered later; it is not a committed near-term feature. The future discussion should cover intended consumers, authentication, authorization, permissions, rate limiting, abuse protection, compatibility, quotas, documentation, and operational cost.

## 4. Items and their fields

Each item should have the following common fields:

- Title.
- Kind/type.
- Optional summary.
- Optional free-text status.
- One primary image.
- Optional price or price range.
- Currency.
- Optional official website URL.
- Kind-specific metadata.
- Markdown description/content.
- Manual ordering within its list.
- Creation/update timestamps and deletion state.

Status is optional free text. There are no user-configurable workflows in the MVP.

Item kinds and status values should not be PostgreSQL enums. Kind-specific validation belongs in Go, and metadata can be stored separately and validated according to the item kind.

### Price model

Prices should be numeric data, not formatted strings.

Recommended columns:
- `price_min NUMERIC(12,2)`
- `price_max NUMERIC(12,2)`
- `currency CHAR(3)`

Rules:
- A single price is represented by `price_min = price_max`.
- Prices must be nonnegative.
- If either price bound is supplied, currency is required.
- If both bounds are supplied, `price_min <= price_max`.
- Workspace default currency is `EUR`.

## 5. Item images and uploads

Image upload is required in the MVP, not a later enhancement.

Each item has one primary image in the MVP. The user can use either:
- An externally hosted image URL, or
- An uploaded image stored by the application.

These two primary image sources must be mutually exclusive.

Image requirements:
- Upload, replace, and remove images.
- Support JPEG, PNG, and WebP.
- Reject SVG.
- Maximum upload size: 10 MB.
- Validate the actual file content server-side, not only the file extension or client-supplied MIME type.
- Use generated storage keys; never trust a user-provided filename as a filesystem path.
- Store attachment metadata in PostgreSQL.
- Store files in persistent filesystem-backed storage.
- Do not rely on an ephemeral container writable layer.
- Do not expose filesystem paths to the frontend.
- Trash preserves image files.
- Permanent purge removes them safely.
- Failure paths during upload/replacement/removal must be designed so database and filesystem state can be reconciled safely.

The UI should support normal file selection and drag-and-drop in the MVP. Pasting an image directly from the clipboard was considered a later convenience, not an MVP requirement.

## 6. Markdown content and version history

Markdown source should be stored in filesystem-backed content storage rather than directly in the main item row. Render Markdown with a maintained renderer, sanitize rendered HTML, and ensure links are safe.

The initial Markdown content size limit is 1 MiB.

The app needs content version history:
- Keep the current version and the previous 20 versions by default.
- Make the history-retention limit configurable per workspace.
- Version history applies to Markdown content.
- No rich Markdown editor is required; a source editor and preview are enough.
- No side-by-side diff or automatic merge in the MVP.

Markdown content versioning is independent from item metadata versioning.

### Suggested content storage model

A filesystem abstraction should be provided in Go for operations such as reading, writing immutable versions, and deleting content safely. The frontend must never know storage paths.

A suggested schema:
- `item_content_versions`: `item_id`, `version`, unique `storage_key`, `content_hash`, `size_bytes`, `created_at`; primary key `(item_id, version)`.
- `item_contents`: `item_id` primary key, `current_version`, `updated_at`, with composite foreign key `(item_id, current_version)` referencing the versions table.

Do not duplicate storage key, hash, and size in the current-pointer table.

Suggested write flow:
1. Write a temporary file.
2. Finalize an immutable version file.
3. Calculate the content hash and size.
4. In a database transaction, check the expected current version/ETag, insert version metadata, and update the current pointer.
5. If a concurrency conflict occurs, preserve the user’s draft and clean up orphaned files safely later.
6. Since filesystem writes and PostgreSQL transactions are not one atomic transaction, recovery and cleanup behavior must be implemented and tested.

Prune old versions only when database references are safely removed and no live reference remains. Backups must include all Markdown files and version metadata.

## 7. External item links

Expanded item details should show exactly three external-link buttons:

1. **Google search** for the item title, with relevant context such as the movie year where useful.
2. **Google search restricted to Reddit**, using a `site:reddit.com` query.
3. **Official website** using the URL explicitly stored on the item.

If no official website URL is stored, hide or disable that button. Never substitute a Google search for the official website action.

The official URL is manually editable in the MVP. Validate URLs to allow only `http` and `https`, rejecting dangerous schemes such as `javascript:`. External links should be opened safely.

## 8. Movie-specific metadata

Movie items have manually entered fields in the MVP:
- Release year.
- Runtime in minutes.
- IMDb URL.
- Streaming platforms available in a configured country.

The default streaming country is `IT`.

There is no TMDB/provider lookup or automatic refresh in the MVP. Public TMDB API integration and automatic data refresh come after the MVP is feature-complete.

Do not scrape IMDb. When TMDB integration is implemented, use its permitted API and verify current terms, attribution, limits, and usage requirements. An IMDb ID or URL may be stored/constructed as allowed by the provider’s data and current terms.

## 9. Search and list behavior

### Global search
- Search item titles only in the MVP.
- Case-insensitive matching.
- Results include the item, list, and folder path.
- Deleted items and descendants of deleted ancestors are excluded.
- Searching Markdown or metadata is deferred.

### List display and ordering
List-level display modes, shared for everyone:
- `compact`
- `thumbnail`
- `grid`

Manual ordering is the default. Users can switch to sorting without destroying the stored manual order.

Basic sorting:
- Title.
- Recently updated.

An optional current-list filter/search can be supported.

Reordering operations must validate that all supplied IDs belong to the intended parent/list, reject duplicates and missing entries, and have clearly specified concurrency behavior.

## 10. Trash, soft deletion, restoration, and purge

Use soft deletion for normal delete operations.

Rules:
- Soft-delete the explicitly selected resource.
- Descendants of a deleted folder/list should be hidden by ancestry, even if those descendants do not have their own `deleted_at`.
- Restoring a parent does not restore children that were independently deleted.
- Trash should show explicitly deleted resources and their former location.
- A child must not be restored into a still-deleted parent. Restore the parent first or use a clearly designed restore/move workflow.
- Purge is a separate, permanent operation that removes database records and stored files safely.
- Destructive operations require explicit UI confirmation.
- Migration rollback affects database schema/data but does not automatically remove filesystem content; document backups and destructive-migration warnings.

Queries must account for deleted ancestors, not only each row’s own `deleted_at`.

## 11. Technology stack and engineering quality

The user explicitly asked that everything be “SOTA and up to date,” including a good Go backend repository, PostgreSQL setup, frontend UI, and API.

Interpret this as: use current, stable, well-maintained, idiomatic practices at implementation time. Do not blindly adopt every new library, and do not overengineer speculative scale. The result should nevertheless have production-quality foundations.

### Backend choices discussed
- Go.
- `net/http` and `chi`.
- PostgreSQL.
- `pgx`.
- SQL-first typed query generation using `sqlc`.
- `golang-migrate` for SQL migrations.
- REST API.
- OpenAPI 3.1 contract committed to the repository.
- Generate TypeScript types/client from OpenAPI.
- Structured logging with `log/slog`.
- Graceful shutdown, health/readiness checks, configuration validation, consistent error handling, connection-pool configuration, tests.
- Clear package boundaries.
- No ORM.
- No microservices, Redis, message queue, or event sourcing in the MVP.

Current stable versions of Go, PostgreSQL, React, Vite, `chi`, `pgx`, `sqlc`, migration tooling, test tooling, and frontend libraries should be verified against authoritative current sources when implementation begins. Do not treat versions mentioned in older examples as current without checking.

### Frontend choices discussed
- React.
- TypeScript.
- Vite.
- Generated API types/client from OpenAPI.
- Modern component architecture.
- Responsive and accessible behavior.
- Attractive, contemporary design: considered fonts, rounded corners, spacing, hierarchy, restrained colors, subtle borders/shadows, image-forward collection views, polished empty/loading/error states.
- Image upload picker and drag-and-drop.
- Keyboard navigation, visible focus, accessible labels, adequate contrast, and no status communicated only by color.

Visual quality is an MVP requirement, not a future polish phase.

## 12. GitHub repository strategy

The project will use **separate GitHub repositories** for the backend and web frontend, with the option to introduce separate repositories for mobile applications in the future. Do not use a monorepo.

### Recommended repositories

1. **`collection-backend`** — Go REST API, PostgreSQL schema and migrations, business logic, file storage, and canonical OpenAPI specification.
2. **`collection-web`** — React, TypeScript, and Vite web application, UI components, frontend tests, and generated API client.
3. **`collection-mobile`** — A possible future repository for a mobile application. Do not create it during the MVP unless mobile development becomes an active requirement.

### Backend repository structure

```text
collection-backend/
├── cmd/
│   └── api/
├── internal/
│   ├── app/
│   ├── config/
│   ├── httpapi/
│   ├── workspace/
│   ├── folders/
│   ├── lists/
│   ├── items/
│   ├── content/
│   ├── metadata/
│   ├── storage/
│   └── database/
├── db/
│   ├── migrations/
│   └── queries/
├── api/
│   └── openapi.yaml
├── tests/
├── docs/
├── .github/
│   └── workflows/
├── .dockerignore
├── .gitignore
├── .env.example
├── Dockerfile
├── Makefile
├── sqlc.yaml
├── go.mod
├── go.sum
├── README.md
└── LICENSE
```

The backend repository owns the API implementation, database migrations, SQL queries, and **canonical OpenAPI specification**.

### Web frontend repository structure

```text
collection-web/
├── public/
├── src/
│   ├── app/
│   ├── components/
│   ├── features/
│   ├── layouts/
│   ├── lib/
│   ├── routes/
│   ├── styles/
│   └── generated/
├── tests/
├── docs/
├── .github/
│   └── workflows/
├── .dockerignore
├── .gitignore
├── .env.example
├── Dockerfile
├── index.html
├── package.json
├── package-lock.json
├── tsconfig.json
├── vite.config.ts
├── README.md
└── LICENSE
```

The frontend repository owns the web UI, frontend state and API integration, generated TypeScript API client, and frontend tests. Use the lockfile for whichever package manager is selected.

### Rules for coordinating separate repositories

- **One source of truth for the API:** The backend repository owns `api/openapi.yaml`. Do not maintain an independent, manually duplicated API contract in the frontend.
- **Generate frontend API types and client code:** Use a maintained generator compatible with the selected OpenAPI specification. Choose the exact generator and integration workflow during implementation planning.
- **Define an explicit cross-repository contract workflow:** Either publish a versioned TypeScript client package or publish/version the OpenAPI specification and generate the client from a pinned version. The implementation plan must choose one approach and document how updates reach the frontend.
- **Check generated code for drift:** CI should verify that generated API code is consistent with its source contract.
- **Keep repositories independently buildable and testable:** The backend must not depend on frontend source code, and the frontend must not depend on backend Go internals or database implementation details.
- **Coordinate breaking API changes:** Document the affected contract, compatible rollout order, and required frontend updates. Avoid merging changes that leave the deployed frontend incompatible with the backend.
- **Use independent CI pipelines:** Backend CI should cover Go formatting, linting, tests, migration validation, and OpenAPI validation. Frontend CI should cover formatting, linting, tests, TypeScript checks, production builds, and API-client drift checks.
- **Keep secrets out of Git:** Include `.env.example` files with placeholders and document the required environment variables. Use GitHub Actions secrets for CI credentials where necessary.
- **Use repository-specific documentation:** Each repository must explain local setup, configuration, testing, and development. Also document how to run the complete application with the web frontend, API, and PostgreSQL together.
- **Keep development orchestration simple:** Docker Compose can live in the backend repository or a dedicated deployment repository later. For the MVP, document how to run the backend and database alongside a separately cloned frontend; do not copy frontend source into the backend repository merely to simplify local startup.
- **Enable automated dependency and security checks** independently in both repositories.

### Local Development Instructions

Both repositories must provide clear, tested local development instructions in their respective `README.md` files. Developers must be able to clone the repositories independently and run the complete application without combining their source code into a monorepo.

#### Prerequisites

Document the supported versions of the following tools when implementation begins:

- Git
- Go
- Node.js and the selected package manager
- Docker and Docker Compose
- PostgreSQL client tools, if required for the chosen workflow

Select and document maintained, compatible versions during implementation. Do not assume versions without verifying compatibility.

#### 1. Clone both repositories

```bash
git clone <backend-repository-url> collection-backend
git clone <frontend-repository-url> collection-web
```

The URLs above are placeholders. Replace them with the actual GitHub repository URLs.

#### 2. Start PostgreSQL and the backend

The backend repository should provide a documented Docker Compose configuration for local PostgreSQL development, with persistent storage for the database and no publicly exposed database port unless needed for local tooling.

From the backend repository:

```bash
cd collection-backend
cp .env.example .env
docker compose up -d
```

Configure the environment variables in `.env` according to the documented local defaults. Never commit real secrets.

The backend development workflow must document how to:

1. Start and stop PostgreSQL.
2. Apply database migrations.
3. Start the Go API locally, or run it using the documented container workflow.
4. Run backend tests and linting.
5. Check API health and readiness.
6. View application and database logs.
7. Reset local development data safely when needed.

The API should be available at `http://localhost:8080` by default, unless the implementation documents a different port. PostgreSQL should remain internal to the Docker network by default.

#### 3. Start the web frontend

From the frontend repository:

```bash
cd collection-web
cp .env.example .env
npm ci
npm run dev
```

Use the actual package manager and scripts defined in `package.json`; the commands above assume npm and a committed `package-lock.json`.

Configure the frontend API base URL to point to the local backend, normally `http://localhost:8080`. Configure and document CORS so the local Vite development server can call the API safely.

The frontend development workflow must document how to:

1. Install dependencies reproducibly.
2. Start the Vite development server.
3. Run tests, linting, and TypeScript checks.
4. Generate or update the API client from the approved, versioned OpenAPI contract.
5. Build and preview the production frontend.
6. Diagnose common API connection and CORS errors.

The web application should be available at `http://localhost:5173` by default, unless the implementation documents a different port.

#### 4. First-run initialization

On the first successful backend startup or first workspace access, initialize the default workspace and required settings according to the agreed bootstrap design.

Initialization must be idempotent: restarting the backend must not create duplicate workspaces or reset existing data.

Document how to verify that the workspace exists and how to initialize a clean development database without affecting other environments.

#### 5. Run the complete application

The standard local development setup should use:

- **Web frontend:** `http://localhost:5173`
- **Go API:** `http://localhost:8080`
- **PostgreSQL:** internal Docker network by default

Run the database and backend using the backend repository's documented workflow, then run the frontend from the separately cloned frontend repository.

A later deployment or development-orchestration repository may provide a unified command for starting the entire stack. This is optional for the MVP and must not introduce a monorepo dependency.

#### 6. Persistent files and development data

The local setup must persist PostgreSQL data, uploaded images, and Markdown content/version files across container restarts.

- Store persistent files in named Docker volumes or documented host directories outside ephemeral container layers.
- Explain how to inspect and reset local data.
- Never use the production data directory for destructive development tests.
- Document how to back up and restore the local database and file storage together.
- Ensure the local reset workflow clearly warns before deleting data.

#### 7. Troubleshooting

Each repository's README should cover common issues, including:

- Missing or incompatible tool versions.
- Port conflicts.
- Database connection failures.
- Migrations that have not been applied.
- Incorrect environment variables.
- CORS and frontend-to-API connectivity.
- Missing or stale generated API client code.
- File storage permissions and missing persistent directories.

### Future mobile development

If a mobile application is introduced, create a separate repository such as `collection-mobile`. It should consume the same versioned API contract as the web frontend. Its client can be generated from OpenAPI or shared through a published package if the mobile technology stack supports that approach.

Do not create an empty mobile repository or add mobile-specific infrastructure to the MVP prematurely.

### Final recommendation

Use **two repositories now: `collection-backend` and `collection-web`**. Give each a clear ownership boundary and independent CI pipeline, while treating the backend-owned OpenAPI specification as the contract between them.

Document local development in both repositories so the database, backend, and frontend can run together without combining their source code. This keeps the codebases independent while providing a reproducible development environment and a straightforward path to a separate mobile repository later.

## 13. Suggested database model in more detail

### `workspaces`
- UUID ID.
- Name.
- Timestamps.

### `workspace_settings`
- `workspace_id` PK/FK.
- `streaming_country_code CHAR(2)` default `IT`.
- `default_currency CHAR(3)` default `EUR`.
- `markdown_history_limit` default 20 previous versions.
- Timestamps.

### `folders`
- `id`, `workspace_id`, nullable `parent_folder_id`, `name`, `sort_order`, timestamps, `deleted_at`.
- Composite unique `(id, workspace_id)`.
- Composite foreign key `(parent_folder_id, workspace_id)` to folders.
- Direct self-parent check.
- Application/domain logic must prevent ancestor cycles.

### `lists`
- `id`, `workspace_id`, nullable `folder_id`, `name`, `description`, `display_mode`, `sort_order`, timestamps, `deleted_at`.
- `display_mode` constrained to `compact`, `thumbnail`, `grid`.
- Composite unique `(id, workspace_id)`.
- Composite FK `(folder_id, workspace_id)` to folders.

### `items`
- `id`, `list_id`, `workspace_id`, `title`, `kind`, `summary`, optional free-text `status`, image source/association, `price_min`, `price_max`, `currency`, `official_website_url`, `sort_order`, `metadata_version INTEGER DEFAULT 1`, timestamps, `deleted_at`.
- Composite FK `(list_id, workspace_id)` to lists.
- Unique `(id, workspace_id)`.
- Constraints for price validity and currency requirement.

### `item_metadata`
- `item_id` PK/FK.
- `data JSONB NOT NULL DEFAULT '{}'`.
- `updated_at`.
- Go validates the JSON shape for each kind. For movies, the shape includes release year, runtime, IMDb URL, and streaming platforms.
- Provider fields and refresh-job data are deferred.

### `item_content_versions`
- `item_id` FK.
- `version`.
- Unique `storage_key`.
- `content_hash`.
- `size_bytes`.
- `created_at`.
- Primary key `(item_id, version)`.

### `item_contents`
- `item_id` PK/FK.
- `current_version`.
- `updated_at`.
- Composite FK `(item_id, current_version)` to `item_content_versions`.

### `attachments`
- Attachment metadata includes ID, item association, generated storage key, optional original filename, detected media type, file size, content hash, and creation timestamp.
- One primary image per item in MVP.
- The final schema must choose a precise, consistent image association. Candidates discussed:
  - `items.primary_attachment_id`, or
  - `attachments.item_id` plus a unique constraint/index.
- Avoid circular foreign-key complications unless they are clearly justified.
- Enforce that an item cannot simultaneously use an external image URL and an uploaded attachment.

### PostgreSQL conventions
- UUIDs, `gen_random_uuid()` on a modern PostgreSQL release.
- `TIMESTAMPTZ`.
- Explicit constraints and indexes.
- Consistent `updated_at` strategy—application-managed or comprehensive triggers, not only on items.
- Index folders by workspace/parent, lists by workspace/folder, items by list/order, workspace/title search, and kind.
- Partial indexes for active records where useful.
- Use SQL-first queries with sqlc.
- Migrations should be reviewed and tested; rollback must be treated carefully when filesystem data exists.

## 14. REST API, ETags, errors, and operations

### Optimistic concurrency
Use optimistic concurrency, not long-lived locks.

- Metadata and Markdown content have independent version streams.
- Metadata version increments on item metadata changes such as title, kind, status, price, image association, official URL, and item placement.
- Markdown content has its own version history.
- Reads return ETags.
- Writes require `If-Match`.
- Missing required `If-Match` -> `428 Precondition Required`.
- Stale ETag -> `412 Precondition Failed`.
- Domain conflict (e.g. move folder into its descendant) -> `409 Conflict`.
- Never silently retry a stale edit with a fresh ETag.
- Move/reorder ETag scope must be explicitly defined in OpenAPI and must not bypass consistency checks.
- Reorder operations affect sibling ordering; their version/concurrency scope must be clearly defined.

### Conflict handling UX
When a stale edit is detected:
- Show a clear message that another change was made.
- Preserve the full user draft, including all changed metadata fields and Markdown.
- Offer **Reload latest** and **Copy my draft**.
- Reload must ask for confirmation before replacing unsaved edits.
- Copy must confirm success; if clipboard access fails, provide selectable text as fallback.
- No automatic merge or side-by-side diff in MVP.
- Network/server errors preserve the draft but are not called version conflicts.

### Error responses
Use RFC 9457 `application/problem+json` with an optional application extension such as `code: "version_conflict"`.
Avoid exposing stack traces, SQL, filesystem paths, or secrets.

Expected status codes as applicable:
- `200`
- `201`
- `204`
- `400`
- `404`
- `409`
- `412`
- `413`
- `422`
- `428`
- `500`

Reject unknown request fields where practical. `PATCH` updates supplied fields. `PUT` replaces a full representation, ordering, or content as appropriate.

### Proposed endpoints (to be finalized in OpenAPI)
- `GET /api/v1/workspace`
- `GET`, `PATCH /api/v1/workspace/settings`
- `GET`, `POST /api/v1/folders`
- `GET`, `PATCH`, `DELETE /api/v1/folders/{id}`
- `POST /api/v1/folders/{id}/move`
- `GET`, `POST /api/v1/lists`
- `GET`, `PATCH`, `DELETE /api/v1/lists/{id}`
- `POST /api/v1/lists/{id}/move`
- `GET`, `POST /api/v1/lists/{id}/items`
- `GET`, `PATCH`, `DELETE /api/v1/items/{id}`
- `POST /api/v1/items/{id}/move`
- Reorder endpoints, e.g. `PUT /api/v1/folders/reorder`, `/lists/reorder`, `/items/reorder`.
- `GET`, `PUT /api/v1/items/{id}/content`
- `GET /api/v1/items/{id}/content/versions`
- `POST /api/v1/items/{id}/content/restore`
- `GET /api/v1/trash`
- `POST /api/v1/trash/{type}/{id}/restore`
- `DELETE /api/v1/trash/{type}/{id}` for purge
- `POST /api/v1/items/{id}/image` for upload/replace multipart
- `DELETE /api/v1/items/{id}/image`
- `GET /api/v1/attachments/{id}/file`

Pagination: `limit` default 50, max 100, and `offset`. Document supported sorting. Reorder must validate that all IDs belong to the intended parent, with no duplicates or missing IDs.

The exact request/response schemas, validation, security requirements, ETags, error cases, and endpoint behavior must be finalized in `openapi.yaml`. The endpoint list above is a proposal, not a completed API specification.

## 15. Frontend requirements in more detail

### Responsive layout
- Desktop: persistent sidebar, main content, optional item detail panel.
- Tablet: collapsible sidebar.
- Mobile: drawer navigation and full-screen item details/forms.
- Responsive cards/grid and good missing-image fallback.

### Navigation
- Nested folders/lists with expand/collapse.
- Breadcrumbs.
- Global search.
- Trash.
- Settings.
- Preserve selected list and expanded folder state when navigating back from an item.

### List view
- Name and description.
- Add item.
- Display mode selector.
- Sort control.
- Optional current-list search/filter.
- Menu for rename/move/delete.
- Item count.
- Manual order retained when switching sort modes.

### Item detail/editor
- Image.
- Common fields.
- Kind-specific metadata.
- Markdown content.
- Official website URL.
- Exactly three external link buttons.
- Editor sections: basic details, kind-specific details, Markdown Edit/Preview, organization.
- File picker and drag-and-drop.
- Save pending state; prevent duplicate submission.
- Warn before navigating away with unsaved edits.
- Destructive confirmation.
- Move destination picker with invalid destinations prevented.

### Trash
- Explicitly deleted resources and former path.
- Restore/purge.
- Clear handling when parent restoration is required first.

### UX states and accessibility
- Useful empty states.
- Loading indicators/skeletons.
- Retry/error states.
- Preserve edits after network/server failures.
- Clear version-conflict UI.
- Keyboard navigation, visible focus, accessible labels, adequate contrast, and no color-only state cues.

### Visual quality
The user specifically asked for a modern, up-to-date frontend with rounded corners, good fonts, and attractive styling. The design specification should define:
- Typography and font strategy.
- Spacing scale.
- Border radii.
- Color and contrast rules.
- Surfaces, borders, shadows.
- Buttons, fields, menus, dialogs, navigation, cards, and detail panels.
- Loading, empty, disabled, error, hover, focus, and destructive states.
- Image cropping/fallback behavior.
- Responsive breakpoints and navigation transitions.

Do not make the product look like an unstyled generic admin dashboard. It should feel like a polished collection product.

## 16. Roadmap clarification — critical sequencing

The user explicitly corrected the roadmap and emphasized that AI is for the very distant future.

### Phase 1: MVP
Complete the core collection app:
- Folders, lists, items, specialized metadata.
- Images.
- Markdown and version history.
- Search.
- Trash/restore/purge.
- ETag-based concurrency and conflict UX.
- Workspace settings.
- Polished responsive UI.
- GitHub CI, local Compose environment, tests, backup/restore.

### Phase 2: TMDB and automatic data refresh
This comes **after the MVP is feature-complete** and before accounts/public API:
- Public TMDB API integration.
- Automatic movie metadata fetching and refresh.
- Appropriate provider error handling, rate limiting, and retries.
- Preserve user-entered overrides; provider refresh must not silently overwrite manual edits.
- Store source/attribution information where appropriate.
- Streaming availability by country may be implemented when a suitable provider and scope are chosen.
- Verify current TMDB API terms, attribution, rate limits, and permitted usage at the time of implementation.
- Do not scrape IMDb.

It is acceptable to keep clean extension points in MVP, but do not build provider lookup, refresh jobs, or provider-specific schema prematurely.

### Phase 3: Accounts and access control
Near-future roadmap, but not immediate MVP:
- Authentication.
- Users and workspace memberships.
- Authorization and membership checks.
- Data-model/API changes.
- Required before public exposure.

### Phase 4: Public API — must be discussed again
The public API is not a committed near-term feature. Revisit the need, consumers, auth, permissions, rate limits, quotas, abuse prevention, versioning, documentation, and operations before implementation. The existence of private `/api/v1` endpoints does not mean the app has an approved public API product.

### Very long-term roadmap: AI/LLM
AI/LLM features are for a **very future roadmap** only. They should not be part of MVP or the TMDB/data-refresh phase.

Possible future ideas:
- Generate or improve Markdown descriptions.
- Pros/cons generation.
- Compare all or selected items in a list in a consistent comparison table.
- Contextual comparisons from an expanded item against other items.
- Ask AI questions about an item, list, or workspace.
- Optional web research with citations.
- Provider-independent AI service boundary if justified; hosted or local models.
- Credentials stay on the backend.
- User explicitly approves before saving AI output; no silent writes.
- Database and saved content remain authoritative.
- Include attribution and uncertainty; do not invent missing facts.
- Saved AI-generated Markdown uses normal content versioning and ETag concurrency.
- One-off Q&A is not automatically saved; saved conversation history could be considered much later.
- No AI provider, AI UI, AI-specific tables, or AI-specific jobs/infrastructure in MVP or Phase 2.

Other future items:
- WebSockets.
- Offline editing.
- Advanced search.
- Rich Markdown editor.
- Side-by-side diff/auto-merge.
- Multiple attachments.
- Custom workflows.

## 17. Backup, deployment, and operations

Requirements:
- Persistent directories/volumes for DB, images, and Markdown versions.
- Coordinated backup of PostgreSQL and filesystem-backed data.
- Document consistency strategy (e.g. pause writes or use an appropriate snapshot process).
- Restore into a clean environment and verify item metadata, Markdown, images, content history, and references.
- A database-only backup is insufficient.
- Do not put user data or real secrets in GitHub.
- Do not use ephemeral container storage for persistent content.
- Migration rollback does not automatically delete filesystem content.
- Safe cleanup/reconciliation for orphaned files after partial failures.
- PostgreSQL stays internal to Docker Compose by default.
- Health checks and sensible restart behavior.
- Future Raspberry Pi/Linux/cloud deployment uses persistent paths, least privilege, and documented upgrade/rollback steps.
- Never publicly expose an unauthenticated writable API.

## 18. Agent work split and orchestration

### Orchestrator
- Treat the design package and OpenAPI as canonical contracts.
- Define interfaces and shared conventions before parallel implementation.
- Ensure all agents agree on names, DTOs, errors, ETags, migrations, and data ownership.
- Avoid conflicting edits to foundational files.
- Integrate, run tests/CI, resolve cross-layer issues.
- Maintain a decision log.
- Keep AI, TMDB, accounts, and public API out of MVP.

### Backend agent
- Go service skeleton and configuration.
- PostgreSQL migrations and schema.
- sqlc queries.
- REST handlers, services, domain validation.
- OpenAPI specification.
- Filesystem content/image storage.
- ETags, conflicts, version history, Trash, upload validation.
- Unit/integration tests.

### Frontend agent
- React/TypeScript/Vite application.
- Generated API client.
- Responsive, polished UI.
- Folder/list/item forms and navigation.
- Markdown editor/preview.
- Image uploads.
- Search, Trash, settings, conflict handling.
- Tests, accessibility, linting, type checks.

### Integration/QA/DevOps agent
- Docker Compose.
- GitHub Actions.
- Integration and end-to-end tests.
- OpenAPI/client generation consistency.
- Acceptance tests.
- Backup/restore scripts and verification.
- CI/repository standards and deployment docs.

A separate architecture/review agent may be useful to review schema/API/security/current best practices without adding speculative features.

## 19. Acceptance criteria / definition of done

The final design package should include measurable acceptance tests covering at least:

1. A fresh clone can be set up from documented instructions.
2. First run idempotently creates a workspace and settings.
3. Folder/list nesting, movement, and ordering work.
4. Invalid hierarchy cycles are rejected.
5. Items support common fields and kind-specific metadata.
6. Image upload validates content and size; replace/remove work; storage persists through container restart.
7. Uploaded and external primary image sources are mutually exclusive.
8. Markdown renders safely; versions persist; retention is respected.
9. Concurrent edits produce `412` and preserve drafts.
10. Required missing `If-Match` returns `428`.
11. Trash hides deleted records and descendants; restore/purge follows the specified rules.
12. Search is case-insensitive title search with full path.
13. Exactly three external-link controls obey the link rules.
14. Responsive UI and accessibility basics work.
15. OpenAPI validates and generated TypeScript client is current.
16. CI runs format/lint/type/test/contract checks.
17. Backup/restore round-trip database, Markdown, and images successfully.
18. No unauthenticated writable API is publicly exposed.
19. AI, TMDB integration, accounts, and public API are not accidentally implemented as MVP scope.

## 20. Open decisions for the next design session

The next session should resolve these, or explicitly record them as implementation gates:

1. **Workspace bootstrap:** how the single workspace is created, named, and initialized idempotently.
2. **Image-source schema:** exact representation for external URL vs uploaded attachment; enforce mutual exclusivity in domain logic and, where practical, the DB.
3. **Attachment relation:** choose `items.primary_attachment_id` or `attachments.item_id` with a unique constraint/index; avoid unnecessary circular FKs.
4. **ETag scope for move/reorder:** exact version scope and conflict behavior.
5. **Trash API semantics:** representations, parent/child restore order, purge cascades.
6. **Workspace scoping:** consistently include workspace IDs in constraints/queries to prepare for future multi-workspace/accounts without implementing accounts now.
7. **OpenAPI TypeScript generator:** choose a maintained generator based on current status when coding starts.
8. **Current stable dependencies:** verify official/current versions of the entire stack at implementation time.
9. **Visual design system:** specify tokens, typography, spacing, radius, component states, responsive behavior, image fallback. Make the app look like a polished collection product.
10. **License:** choose an appropriate repository license before public/open-source release; private repo still needs a decision eventually.
11. **Public API:** explicitly re-discuss later; not a current commitment.
12. **TMDB terms:** verify current policies, attribution, limits, and commercial/non-commercial terms before integration.
13. **Storage consistency and recovery:** define orphan cleanup and failure recovery.
14. **API pagination/sorting:** define exact response envelope and stable sort tie-breakers.
15. **Generated files:** decide whether generated API client is committed or generated in CI, and enforce drift detection.
16. **CI/security tooling:** select maintained tools and pin versions appropriately based on current status.

## 21. Final handoff documents expected

The next ChatGPT session should turn the above into a coherent package, not merely return another recap.

### `ORCHESTRATOR_BRIEF.md`
- Project goal and non-goals.
- Canonical contracts and decision rules.
- Agent responsibilities.
- Parallelization plan and dependencies.
- Integration checkpoints.
- Definition of done.
- Rules for scope control and decision logging.

### `PRODUCT.md`
- Vision, users, hierarchy, item model, workflows.
- Detailed MVP features and exclusions.
- Trash, search, links, metadata, settings.
- Roadmap and phase boundaries.

### `ARCHITECTURE.md`
- Current stack and rationale.
- Monorepo layout.
- Backend/frontend boundaries.
- Storage architecture.
- Runtime/configuration.
- Security and future extension points.
- CI and quality strategy.

### `DATA_MODEL.md`
- ER model/table descriptions.
- Columns/types/nullability/defaults.
- PK/FK/unique/check constraints.
- Indexes.
- Soft delete/Trash semantics.
- Content versioning and attachments.
- Migration strategy and workspace scoping.

### `API.md`
- REST conventions.
- Concrete endpoint definitions.
- Request/response schemas.
- OpenAPI requirements.
- Pagination/sorting.
- ETags/If-Match/versioning.
- Error format and status codes.
- Uploads/content versions/Trash.
- Security boundary and public API caveat.

### `UI_SPEC.md`
- Navigation and responsive layout.
- List modes and ordering.
- Item detail/editor.
- Image upload.
- Markdown editing/preview/history.
- Search, Trash, settings.
- Conflict UI.
- Design tokens and visual system.
- Accessibility and UI states.

### `ACCEPTANCE_TESTS.md`
- Unit, integration, contract, end-to-end, storage-failure, concurrency, and restore tests.
- Verifiable criteria tied to MVP requirements.

### `IMPLEMENTATION_PLAN.md`
- Phases and dependencies.
- Workstreams for backend, frontend, integration/QA.
- Safe parallel execution plan.
- Milestones, CI gates, review checkpoints.
- Explicit scope exclusions.

### `BACKUP_AND_DEPLOYMENT.md`
- Local setup.
- Environment variables.
- Docker Compose.
- Persistent directories/volumes.
- Backup/restore procedure and verification.
- Future Linux/Raspberry Pi/cloud notes.
- Security restrictions before public exposure.

The final package may also include a `README.md`, `.env.example` specification, a decision log, and an explicit implementation checklist. Actual `openapi.yaml`, SQL migrations, and source code are implementation artifacts and do not yet exist.

---

# Part II — Concise user decisions and assistant recommendations

This section records the main choices in a compact decision-log format for quick reference.

| Topic | Decision / recommendation | Status |
|---|---|---|
| Initial users | User and girlfriend share one workspace | Agreed |
| Accounts in MVP | None | Agreed |
| Public exposure | Never expose unauthenticated writable API | Mandatory |
| Public API product | Re-discuss later; not committed near-term | Explicit user clarification |
| Future accounts | Near future, after MVP/data enrichment | Roadmap |
| AI/LLM | Very distant future, not MVP or Phase 2 | Explicit user clarification |
| TMDB and automatic refresh | After MVP is feature-complete | Explicit user clarification |
| Repository | One GitHub monorepo initially | Recommended and accepted as direction |
| Backend | Go, chi/net/http, pgx, sqlc, golang-migrate | Agreed direction |
| Database | PostgreSQL | Agreed |
| Frontend | React + TypeScript + Vite | Agreed direction |
| API contract | OpenAPI 3.1; generate TS client/types | Agreed direction |
| Storage | PostgreSQL + persistent filesystem for Markdown/images | Agreed direction |
| Image uploads | MVP; JPEG/PNG/WebP; 10 MB; reject SVG | Agreed |
| Markdown versions | Current + 20 prior by default | Agreed |
| Default country/currency | IT / EUR | Agreed |
| Item placement | Exactly one list in MVP | Agreed |
| List views | compact / thumbnail / grid | Agreed |
| Search | Case-insensitive title search only | Agreed |
| Concurrency | ETags, If-Match; stale = 412; missing = 428 | Agreed |
| Conflict UX | Preserve draft; reload latest or copy draft | Agreed |
| Trash | Soft delete, ancestry-aware hiding, restore/purge | Agreed |
| Mobile repository | Decide when mobile is real; no empty repo now | Recommended |
| Visual polish | Contemporary UI, typography, rounded corners, responsive/accessibility | Explicit user requirement |
| GitHub workflow | Actions, CI, reviews, dependency/security checks, no secrets | Explicit user requirement |
| WebSockets | Deferred | Agreed |
| Provider lookups in MVP | No | Agreed |
| Offline editing / auto-merge / rich editor | Deferred | Agreed |

---

# Part III — Instructions for the next session

Read this archive carefully before answering. The user wants a **complete design document and a package of handoff documents** for an orchestrator agent and child agents.

Be concrete, opinionated, and consistent. Do not just repeat this file. Turn it into a set of implementation-ready design docs. Verify current authoritative documentation when the answer depends on current versions or current TMDB policies. Do not invent current version numbers.

Preserve the exact roadmap order:
1. MVP.
2. TMDB/public metadata fetching and automatic refresh after MVP is feature-complete.
3. Accounts/access control in the near future.
4. Public API: re-discuss later; no current commitment.
5. AI/LLM: very distant future.

Do not bring AI into MVP or Phase 2. Do not make a public API a committed near-term deliverable. Do not allow public unauthenticated writes.

The user expects the documents to be suitable for saving to GitHub and handing directly to an orchestrator agent. Resolve schema/API details wherever possible; mark any remaining decision gates explicitly. Ensure that all documents agree on table names, endpoint names, ETag semantics, image storage, Trash behavior, and phase boundaries.
