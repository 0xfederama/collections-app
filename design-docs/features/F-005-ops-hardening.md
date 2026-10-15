# F-005 — Ops hardening (privacy + backups + audits)

Status: approved    Release: backend 1.2.1 (web unchanged)    Roadmap: ROADMAP.md §7 items 1–2
Repos: backend | parent    Approved by the user: 2026-10-15

## Why
Uploaded photos keep their EXIF, which can include the GPS position of your home. Backups exist but only run if someone
schedules them by hand, and nothing says when one was missed. Dependency audits exist but aren't part of releasing.

## User stories
### Backend
- **F005-B1 · Strip metadata from uploaded originals.** As a user, I want uploaded images stored without EXIF/GPS and
  other metadata, so that a photo never leaks where it was taken. Acceptance:
  - On upload, the stored original keeps no EXIF (incl. GPS), XMP, IPTC or comment blocks, for JPEG, PNG and WebP.
    Thumbnails are already re-encoded and clean (`internal/images/process.go`); keep them as they are.
  - Prefer lossless stripping (drop the metadata segments/chunks) over re-encoding. The displayed orientation must not
    change: either keep only the orientation information or apply it, and keep the stored width/height consistent.
    An ICC colour profile may be kept.
  - A one-off command strips **existing** originals in place (idempotent, reports counts, safe to re-run, never touches a
    file it can't parse). It's runnable inside the prod api container; the backend README says how
    (`./deploy/prod exec api …` or a `make` target), and the parent runbook links it.
  - Tests: a fixture JPEG with GPS EXIF, a PNG with `eXIf`/`tEXt`, and a WebP with EXIF/XMP come out clean; the
    orientation fixture still displays the same; the backfill run twice changes nothing the second time.
  - No new dependency unless the standard library route is clearly unreasonable (flag it if so).
- **Release:** tag backend `v1.2.1` after the merge, with `make audit` run first (D-084).

### Parent (top-level orchestrator)
- **F005-P1 · Scheduled backup** (done 2026-10-15): systemd units in `deploy/server/systemd/` (nightly backup + prune,
  `Persistent=true`) and install steps in `deploy/README.md`.
- **F005-P2 · Backup check** (done 2026-10-15): `./deploy/prod backup-status [hours]` fails when there is no backup, the
  newest is incomplete, or it's older than 26 h.
- **F005-P3 · Audits before tags** (done 2026-10-15): rule in AGENT_WORKFLOW §1b "Test runs" (D-084).
- After B1 merges: bump the pointer, add the backfill step to the deploy runbook, run it on the server (you).

### You (on the server)
- Install the timer (deploy/README.md "Backups"), then run `./deploy/prod backup-status` the next day.
- After deploying backend 1.2.1, run the EXIF backfill once.

## Contract impact
None.

## Constraints
- Lean workflow as F-007/F-003 (D-079/D-081): Sonnet 5.5 orchestrator, workers write code only, the orchestrator runs the
  gate once at the end, one PR.
- Never lose data: the backfill rewrites files in place only after the stripped file is fully written (write temp, then
  rename), and it never deletes an original.

## Out of scope (stays in the pool)
- Node 26 LTS (from 2026-10-28), TypeScript 7, the VoiceOver pass, the `VITE_API_MOCKS=1` browser check.
- Your backup → wipe → restore drill, the exposure check script, 40 MP and slow-network upload checks.
- CI and Dependabot (D-084: not for now).

## Repo breakdown (filled by the repo orchestrators)
### Backend
| Task | Story | Branch | Worker result | Flags reviewed | PR |
|---|---|---|---|---|---|
| T1 `images.Strip` (JPEG/PNG/WebP lossless; JPEG keeps a minimal orientation-only EXIF) + use in `Process` + tests | F005-B1 | `feature/F005-B1-strip-image-metadata` | dispatched 2026-10-15 | | |
| T2 `api strip-images` backfill subcommand (sqlc queries, idempotent, size/sha fix) + tests + README | F005-B1 | same | dispatched 2026-10-15 (same worker) | | |

## Log
- 2026-10-15: brief written with the user (pool items 1+2 merged into one round, no CI, D-084); parent stories P1–P3 done.
