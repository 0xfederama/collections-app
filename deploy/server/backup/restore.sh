#!/usr/bin/env bash
# Restores a backup made by backup.sh into fresh volumes (BACKUP_AND_DEPLOYMENT §4).
# Usage: scripts/restore.sh <backup-dir> [--force]
# Refuses to touch non-empty pgdata/appdata volumes. --force deletes them after a typed confirmation.
# Order: check hashes → empty volumes → restore dump → extract images → verify → migrate up → start the whole stack.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
force=0
backup_arg=""
for arg in "$@"; do
  case "$arg" in
    --force) force=1 ;;
    -*) backup_arg="" && break ;;
    *) if [ -z "$backup_arg" ]; then backup_arg="$arg"; else backup_arg="" && break; fi ;;
  esac
done
if [ -z "$backup_arg" ] || [ ! -d "$backup_arg" ]; then
  echo "usage: scripts/restore.sh <backup-dir> [--force]" >&2
  exit 2
fi
backup="$(cd "$backup_arg" && pwd)"

# On the Pi, hold the release lock of the stack being restored (prod: lock, test stack: test-lock), so the release
# check never deploys to it or restarts it mid-restore. Waits up to 5 minutes for a running release to finish.
release_state="$here/../.release-state"
if command -v flock >/dev/null && [ -d "$release_state" ]; then
  lockname=lock; [ "${PI_STACK:-prod}" = test ] && lockname=test-lock
  exec 8>"$release_state/$lockname"
  flock -w 300 8 || { echo "a release is still running on this stack; try again in a few minutes" >&2; exit 1; }
fi

# shellcheck source=lib/backup-common.sh
. "$here/lib/backup-common.sh"
check_tools
check_backup_dir "$backup"

manifest_migration="$(jq -r '.migration_version' "$MANIFEST")"
local_migration="$(latest_local_migration)"
# On the Pi there is no backend checkout: the migrations live in the api image (BACKEND_VERSION), and
# `migrate` below fails loudly if the backup is newer than that image. Only compare when a checkout exists.
if [ "$local_migration" -gt 0 ] && [ "$manifest_migration" -gt "$local_migration" ]; then
  die "the backup is at migration $manifest_migration but this checkout only has up to $local_migration: update the code first"
fi

# Which target volumes hold data? (mounting creates them empty if they do not exist yet)
nonempty=()
if [ -n "$(dc run --rm --no-deps -T --entrypoint sh db -c 'ls -A /var/lib/postgresql' 2>/dev/null </dev/null)" ]; then
  nonempty+=(pgdata)
fi
if [ -n "$(carrier ro sh -c 'ls -A /data' 2>/dev/null </dev/null)" ]; then
  nonempty+=(appdata)
fi

if [ "${#nonempty[@]}" -gt 0 ]; then
  if [ "$force" != 1 ]; then
    die "target volume(s) not empty: ${nonempty[*]}. Re-run with --force to delete them first"
  fi
  answer=""
  read -r -p "This DELETES the current database and uploaded files (${nonempty[*]}). Type 'restore' to continue: " answer || true
  if [ "$answer" != "restore" ]; then
    echo "aborted"
    exit 1
  fi
  echo "removing containers and volumes"
  dc down --volumes --remove-orphans
fi

echo "starting a fresh database"
dc up -d --no-deps --wait db >/dev/null
wait_for_db

echo "restoring the database"
dc exec -T db pg_restore -U collection -d collection --no-owner --no-privileges --single-transaction --exit-on-error <"$DB_DUMP"

echo "extracting images"
case "$FILES_ARCHIVE" in
  *.zst) need zstd "needed to read $FILES_ARCHIVE"; decompress=(zstd -dc -q) ;;
  *.gz) decompress=(gzip -dc) ;;
  *) die "unknown archive type: $FILES_ARCHIVE" ;;
esac
# The files belong to the api's unprivileged user, not root.
"${decompress[@]}" "$FILES_ARCHIVE" |
  carrier rw sh -c "tar -xf - -C /data && chown -R $API_UID:$API_UID /data"

echo "verifying against the manifest"
"$here/verify-restore.sh" "$backup"

echo "applying newer migrations (if any)"
dc run --rm migrate

# `down` above removed every container (web, and tunnel/logs when their profiles are on), so start them all,
# not only the api: otherwise the app is unreachable after a restore.
echo "starting the stack"
dc up -d --wait
echo "restore complete from $backup"
