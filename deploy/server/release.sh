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

before="$(git -C "$root" rev-parse HEAD)"
git -C "$root" pull -q --ff-only || echo "[release] git pull failed (local changes on the Pi?)" >&2
if [ "$before" != "$(git -C "$root" rev-parse HEAD)" ] && [ -f "$versions" ] \
  && ! git -C "$root" diff --quiet "$before" HEAD -- deploy/; then
  echo "[release] deploy/ changed ($before -> $(git -C "$root" rev-parse --short HEAD)), re-applying"
  "$root/deploy/prod" up -d --remove-orphans
fi

be="$(latest collections-app-backend)"
web="$(latest collections-app-frontend-web)"
[ -n "$be" ] || [ -n "$web" ] || exit 0
[ "$be" = "$BACKEND_VERSION" ] && [ "$web" = "$WEB_VERSION" ] && exit 0

log() { echo "[release] $*"; }
save() { printf 'BACKEND_VERSION=%s\nWEB_VERSION=%s\n' "$BACKEND_VERSION" "$WEB_VERSION" >"$versions"; }

echo "$GITHUB_TOKEN" | docker login ghcr.io -u 0xfederama --password-stdin >/dev/null

if [ -n "$be" ] && [ "$be" != "$BACKEND_VERSION" ]; then
  log "backend $BACKEND_VERSION -> $be"
  if [ -n "$BACKEND_VERSION" ]; then "$root/deploy/prod" backup; fi
  BACKEND_VERSION="$be"
  BACKEND_VERSION="$be" "$root/deploy/prod" pull api
  BACKEND_VERSION="$be" "$root/deploy/prod" up -d db migrate api
  save
  log "backend $be is live"
fi

if [ -n "$web" ] && [ "$web" != "$WEB_VERSION" ]; then
  [ -n "$BACKEND_VERSION" ] || { log "web $web waits for a backend release"; exit 0; }
  log "web ${WEB_VERSION:-none} -> $web"
  WEB_VERSION="$web"
  WEB_VERSION="$web" "$root/deploy/prod" pull web
  WEB_VERSION="$web" "$root/deploy/prod" up -d web
  save
  log "web $web is live"
fi
