#!/usr/bin/env bash
# Deploys the latest published GitHub Release of each service (D-117). Run every minute by
# collection-release.timer; does nothing when both versions are already deployed.
#
# Publishing a Release (marked latest) in a repo is the prod approval. A tag alone is not.
# Order: backend first (backup, migrations embedded in the api image, api), then web.
# Every run also fast-forwards this checkout: pushed deploy/ changes apply within a minute.
# Needs GITHUB_TOKEN (read-only) in deploy/server/.env: API rate limit and GHCR pulls.
#
# RELEASE_STACK=test (roadmap #22): the test stack (./deploy/pitest) instead, tracking the newest published
# release including pre-releases, with no backup. With TEST_STACK=1 in .env, the prod run starts it first.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
stack="${RELEASE_STACK:-prod}"
state="$here/.release-state"
mkdir -p "$state"
if [ "$stack" = test ]; then
  versions="$here/versions-test.env"; pfx="test-"; stack_cmd="$root/deploy/pitest"
else
  versions="$here/versions.env"; pfx=""; stack_cmd="$root/deploy/prod"
fi

# The test stack has its own lock, so the prod run (which holds the main lock) can start it.
exec 9>"$state/${pfx}lock"
flock -n 9 || exit 0

# Sync deploy/ first; if this script itself changed, restart with the new copy (the lock fd is inherited),
# so a fix pushed to release.sh is never run by the old version.
if [ "$stack" = prod ] && [ -z "${RELEASE_REEXEC:-}" ]; then
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

# Alerts (roadmap #24, prod only): every finished run pings "collection-release". A single failed run
# (network blip) sends nothing; healthchecks.io alerts when no ok ping arrives for its grace time
# (expired token, dead timer, Pi offline). Deploy results go to "collection-deploy".
hc() { [ "$stack" = prod ] && "$here/hc.sh" "$@"; return 0; }
[ "$stack" = prod ] && trap '[ $? -eq 0 ] && "$here/hc.sh" collection-release ok' EXIT

# Test first: a failure there is logged and never stops the prod check.
if [ "$stack" = prod ] && [ "${TEST_STACK:-}" = 1 ]; then
  RELEASE_STACK="test" "$here/release.sh" || true
fi

BACKEND_VERSION=""; WEB_VERSION=""
# shellcheck disable=SC1090
[ -f "$versions" ] && . "$versions"

# Release tag to deploy, without the leading v. Conditional request: a 304 costs no rate limit.
# prod: the release marked latest. test: the highest version among published releases, pre-releases included.
latest() {
  local repo="$1" etag="$state/$pfx$1.etag" body="$state/$pfx$1.json" code url
  url="https://api.github.com/repos/0xfederama/$repo/releases/latest"
  [ "$stack" = test ] && url="https://api.github.com/repos/0xfederama/$repo/releases?per_page=20"
  local -a hdr=(-H "Authorization: Bearer $GITHUB_TOKEN" -H "Accept: application/vnd.github+json")
  [ -s "$etag" ] && hdr+=(-H "If-None-Match: $(cat "$etag")")
  code="$(curl -sS -o "$body.new" -w '%{http_code}' -D "$state/$pfx$1.headers" "${hdr[@]}" "$url")" || return 1
  case "$code" in
    200) mv "$body.new" "$body"; grep -i '^etag:' "$state/$pfx$1.headers" | cut -d' ' -f2- | tr -d '\r' >"$etag" ;;
    304) rm -f "$body.new" ;;
    404) rm -f "$body.new"; return 0 ;;   # no release published yet
    *) echo "release check for $repo: HTTP $code" >&2; rm -f "$body.new"; return 1 ;;
  esac
  [ -f "$body" ] || return 0
  if [ "$stack" = test ]; then
    jq -r '.[] | select(.draft | not) | .tag_name' "$body" | sed 's/^v//' | sort -V | tail -n1
  else
    jq -r '.tag_name // empty' "$body" | sed 's/^v//'
  fi
}

if [ -n "${RELEASE_BEFORE:-}" ] && [ -f "$versions" ] && ! git -C "$root" diff --quiet "$RELEASE_BEFORE" HEAD -- deploy/; then
  echo "[release] deploy/ changed ($RELEASE_BEFORE -> $(git -C "$root" rev-parse --short HEAD)), re-applying"
  "$stack_cmd" up -d --remove-orphans || echo "[release] re-apply failed, continuing with the release check" >&2
fi

be="$(latest collections-app-backend)"
web="$(latest collections-app-frontend-web)"
# A version that failed to deploy is not retried every minute: publish a newer release (or delete
# .release-state/<repo>.failed) to try again.
[ "$be" = "$(cat "$state/${pfx}backend.failed" 2>/dev/null)" ] && be="$BACKEND_VERSION"
[ "$web" = "$(cat "$state/${pfx}web.failed" 2>/dev/null)" ] && web="$WEB_VERSION"
[ -n "$be" ] || [ -n "$web" ] || exit 0
[ "$be" = "$BACKEND_VERSION" ] && [ "$web" = "$WEB_VERSION" ] && exit 0

log() { echo "[release${pfx:+ test}] $*"; }
save() { printf 'BACKEND_VERSION=%s\nWEB_VERSION=%s\n' "$BACKEND_VERSION" "$WEB_VERSION" >"$versions"; }

echo "$GITHUB_TOKEN" | docker login ghcr.io -u 0xfederama --password-stdin >/dev/null

prod() { "$stack_cmd" "$@"; }
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
# A release published before its image build finished is not a failure: wait and retry next minute.
# Only if the image is still missing after an hour (build broken?) is it reported, once.
waiting() {
  local f="$state/${pfx}$1.waiting" since
  if [ "$(cut -d' ' -f1 "$f" 2>/dev/null)" != "$2" ]; then echo "$2 $(date +%s)" >"$f"; return 0; fi
  since="$(cut -d' ' -f2 "$f")"
  if [ $(( $(date +%s) - since )) -gt 3600 ] && ! grep -q ' alerted$' "$f"; then
    hc collection-deploy fail "$1 $2: image still not on GHCR after an hour (check the release-image workflow)"
    echo "$2 $since alerted" >"$f"
  fi
}
if [ -n "$be" ] && [ "$be" != "$BACKEND_VERSION" ] && ! BACKEND_VERSION="$be" prod pull -q api migrate >/dev/null 2>&1; then
  log "backend $be: image not on GHCR yet (build still running?), retrying next minute"
  waiting backend "$be"
  be="$BACKEND_VERSION"
fi
if [ -n "$web" ] && [ "$web" != "$WEB_VERSION" ] && ! WEB_VERSION="$web" prod pull -q web >/dev/null 2>&1; then
  log "web $web: image not on GHCR yet (build still running?), retrying next minute"
  waiting web "$web"
  web="$WEB_VERSION"
fi

if [ -n "$be" ] && [ "$be" != "$BACKEND_VERSION" ]; then
  log "backend ${BACKEND_VERSION:-none} -> $be"
  if (
    set -e
    if [ -n "$BACKEND_VERSION" ]; then
      prod stop api
      [ "$stack" = test ] || prod backup
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
    hc collection-deploy ok "backend $be is live"
  else
    drop_preflight
    echo "$be" >"$state/${pfx}backend.failed"
    log "FAILED to deploy backend $be; back to ${BACKEND_VERSION:-none} (not retried until a newer release)"
    hc collection-deploy fail "backend $be failed, rolled back to ${BACKEND_VERSION:-none}: see journalctl -u collection-release"
    [ -z "$BACKEND_VERSION" ] || prod up -d --no-deps --wait api || log "the previous api did not come back: check '${stack_cmd#"$root/"} logs api'"
    exit 1
  fi
fi

if [ -n "$web" ] && [ "$web" != "$WEB_VERSION" ]; then
  [ -n "$BACKEND_VERSION" ] || { log "web $web waits for a backend release"; exit 0; }
  log "web ${WEB_VERSION:-none} -> $web"
  if WEB_VERSION="$web" prod up -d --no-deps --wait web; then
    WEB_VERSION="$web"
    save
    log "web $web is live"
    hc collection-deploy ok "web $web is live"
  else
    echo "$web" >"$state/${pfx}web.failed"
    log "FAILED to deploy web $web; rolling back to ${WEB_VERSION:-none} (not retried until a newer release)"
    hc collection-deploy fail "web $web failed, rolled back to ${WEB_VERSION:-none}: see journalctl -u collection-release"
    [ -z "$WEB_VERSION" ] || prod up -d --no-deps --wait web || log "the previous web did not come back: check '${stack_cmd#"$root/"} logs web'"
    exit 1
  fi
fi

# Keep the SD card from filling up: drop images unused for a week (a rollback re-pulls if needed).
docker image prune -af --filter "until=168h" >/dev/null || true
