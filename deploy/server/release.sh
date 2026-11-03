#!/usr/bin/env bash
# Deploys the latest published GitHub Release of each service (D-117). Run every minute by
# collection-release.timer; does nothing when both versions are already deployed.
#
# Publishing a Release (marked latest) in a repo is the prod approval. A tag alone is not.
# Order: backend first (backup, migrations embedded in the api image, api), then web.
# Every run also fast-forwards this checkout: pushed deploy/ changes apply within a minute.
# Needs GITHUB_TOKEN (read-only) in deploy/server/.env: API rate limit and GHCR pulls.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
versions="$here/versions.env"
state="$here/.release-state"
mkdir -p "$state"

exec 9>"$state/lock"
flock -n 9 || exit 0

# Sync deploy/ first; if this script itself changed, restart with the new copy (the lock fd is inherited),
# so a fix pushed to release.sh is never run by the old version.
if [ -z "${RELEASE_REEXEC:-}" ]; then
  before="$(git -C "$root" rev-parse HEAD)"
  git -C "$root" pull -q --ff-only || echo "[release] git pull failed (local changes on the Pi?)" >&2
  if [ "$before" != "$(git -C "$root" rev-parse HEAD)" ]; then
    RELEASE_REEXEC=1 RELEASE_BEFORE="$before" exec "$here/release.sh"
  fi
fi

set -a
# shellcheck disable=SC1091
. "$here/.env"
set +a
: "${GITHUB_TOKEN:?set GITHUB_TOKEN in deploy/server/.env}"

BACKEND_VERSION=""; WEB_VERSION=""
# shellcheck disable=SC1090
[ -f "$versions" ] && . "$versions"

# Latest published release tag of a repo, without the leading v. Conditional request: a 304 costs no rate limit.
latest() {
  local repo="$1" etag="$state/$1.etag" body="$state/$1.json" code
  local -a hdr=(-H "Authorization: Bearer $GITHUB_TOKEN" -H "Accept: application/vnd.github+json")
  [ -s "$etag" ] && hdr+=(-H "If-None-Match: $(cat "$etag")")
  code="$(curl -sS -o "$body.new" -w '%{http_code}' -D "$state/$1.headers" "${hdr[@]}" \
    "https://api.github.com/repos/0xfederama/$repo/releases/latest")" || return 1
  case "$code" in
    200) mv "$body.new" "$body"; grep -i '^etag:' "$state/$1.headers" | cut -d' ' -f2- | tr -d '\r' >"$etag" ;;
    304) rm -f "$body.new" ;;
    404) rm -f "$body.new"; return 0 ;;   # no release published yet
    *) echo "release check for $repo: HTTP $code" >&2; rm -f "$body.new"; return 1 ;;
  esac
  [ -f "$body" ] && jq -r '.tag_name // empty' "$body" | sed 's/^v//'
}

if [ -n "${RELEASE_BEFORE:-}" ] && [ -f "$versions" ] && ! git -C "$root" diff --quiet "$RELEASE_BEFORE" HEAD -- deploy/; then
  echo "[release] deploy/ changed ($RELEASE_BEFORE -> $(git -C "$root" rev-parse --short HEAD)), re-applying"
  "$root/deploy/prod" up -d --remove-orphans || echo "[release] re-apply failed, continuing with the release check" >&2
fi

be="$(latest collections-app-backend)"
web="$(latest collections-app-frontend-web)"
# A version that failed to deploy is not retried every minute: publish a newer release (or delete
# .release-state/<repo>.failed) to try again.
[ "$be" = "$(cat "$state/backend.failed" 2>/dev/null)" ] && be="$BACKEND_VERSION"
[ "$web" = "$(cat "$state/web.failed" 2>/dev/null)" ] && web="$WEB_VERSION"
[ -n "$be" ] || [ -n "$web" ] || exit 0
[ "$be" = "$BACKEND_VERSION" ] && [ "$web" = "$WEB_VERSION" ] && exit 0

log() { echo "[release] $*"; }
save() { printf 'BACKEND_VERSION=%s\nWEB_VERSION=%s\n' "$BACKEND_VERSION" "$WEB_VERSION" >"$versions"; }

echo "$GITHUB_TOKEN" | docker login ghcr.io -u 0xfederama --password-stdin >/dev/null

prod() { "$root/deploy/prod" "$@"; }
psql_admin() { prod exec -T db psql -U collection -d postgres -q -v ON_ERROR_STOP=1 "$@"; }
drop_preflight() { psql_admin -c "DROP DATABASE IF EXISTS collection_preflight" >/dev/null 2>&1 || true; }

# Backend deploy, safe to fail at any step:
#   1. pull the new image (nothing changes yet)
#   2. stop the api, back up (disaster copy only, never part of a rollback)
#   3. preflight: run the new migrations on a throwaway copy of the database; if they fail, the real
#      database was never touched and the old api simply starts again
#   4. migrate the real database and start the new api, waiting until it is healthy
# If 4 fails, the old api starts again on the migrated schema. That works because every migration
# must be backward compatible with the previous release (expand/contract, D-118).
if [ -n "$be" ] && [ "$be" != "$BACKEND_VERSION" ]; then
  log "backend ${BACKEND_VERSION:-none} -> $be"
  if (
    set -e
    BACKEND_VERSION="$be" prod pull api migrate
    if [ -n "$BACKEND_VERSION" ]; then
      prod stop api
      prod backup
      log "preflight: migrations on a copy of the database"
      drop_preflight
      psql_admin -c "CREATE DATABASE collection_preflight TEMPLATE collection"
      BACKEND_VERSION="$be" prod run --rm --no-deps \
        -e "DATABASE_URL=postgres://db:5432/collection_preflight?user=collection&password=$POSTGRES_PASSWORD&sslmode=disable" migrate
      drop_preflight
    fi
    BACKEND_VERSION="$be" prod up -d --wait api
  ); then
    BACKEND_VERSION="$be"
    save
    log "backend $be is live"
  else
    drop_preflight
    echo "$be" >"$state/backend.failed"
    log "FAILED to deploy backend $be; back to ${BACKEND_VERSION:-none} (not retried until a newer release)"
    [ -z "$BACKEND_VERSION" ] || prod up -d --no-deps --wait api || log "the previous api did not come back: check 'deploy/prod logs api'"
    exit 1
  fi
fi

if [ -n "$web" ] && [ "$web" != "$WEB_VERSION" ]; then
  [ -n "$BACKEND_VERSION" ] || { log "web $web waits for a backend release"; exit 0; }
  log "web ${WEB_VERSION:-none} -> $web"
  if WEB_VERSION="$web" prod pull web && WEB_VERSION="$web" prod up -d --no-deps --wait web; then
    WEB_VERSION="$web"
    save
    log "web $web is live"
  else
    echo "$web" >"$state/web.failed"
    log "FAILED to deploy web $web; rolling back to ${WEB_VERSION:-none} (not retried until a newer release)"
    [ -z "$WEB_VERSION" ] || prod up -d --no-deps --wait web || log "the previous web did not come back: check 'deploy/prod logs web'"
    exit 1
  fi
fi

# Keep the SD card from filling up: drop images unused for a week (a rollback re-pulls if needed).
docker image prune -af --filter "until=168h" >/dev/null || true
