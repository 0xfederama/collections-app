#!/usr/bin/env bash
# Off-Pi copies of the backups on Google Drive, encrypted by rclone crypt (roadmap #21).
#
#   offsite.sh upload            copy the newest local backup (run nightly after `deploy/prod backup`)
#   offsite.sh list              backups on Drive, newest first
#   offsite.sh get <name> [dir]  download one back (default dir: $BACKUP_DIR), then `deploy/prod restore`
#
# Settings in deploy/server/.env: OFFSITE_REMOTE (default gdrive-crypt:collections-backups), OFFSITE_KEEP (30).
# Drive is never synced from the Pi: only copy and an explicit prune, so a wiped SD card can't wipe Drive.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
set -a
# shellcheck disable=SC1091
. "$here/.env"
set +a
remote="${OFFSITE_REMOTE:-gdrive-crypt:collections-backups}"
keep="${OFFSITE_KEEP:-30}"
backups="${BACKUP_DIR:-/srv/collection/backups}"
command -v rclone >/dev/null || { echo "error: rclone is not installed (sudo apt install rclone)" >&2; exit 1; }

list() { rclone lsf --dirs-only "$remote" 2>/dev/null | tr -d / | grep -E '^[0-9]{8}T[0-9]{6}Z$' | sort -r; }

case "${1:-}" in
  upload)
    newest="$(cd "$backups" && printf '%s\n' * | grep -E '^[0-9]{8}T[0-9]{6}Z$' | sort -r | head -n1 || true)"
    [ -n "$newest" ] || { echo "error: no local backup in $backups" >&2; exit 1; }
    [ -f "$backups/$newest/manifest.json" ] || { echo "error: $newest is incomplete (no manifest.json)" >&2; exit 1; }
    echo "uploading $newest to $remote"
    rclone copy --checksum "$backups/$newest" "$remote/$newest"
    # Verify: the uploaded files must match the local ones (decrypted on the fly).
    rclone cryptcheck "$backups/$newest" "$remote/$newest" 2>/dev/null || rclone check "$backups/$newest" "$remote/$newest"
    count=0
    while IFS= read -r name; do
      count=$((count + 1))
      if [ "$count" -gt "$keep" ]; then echo "pruning $name from Drive"; rclone purge "$remote/$name"; fi
    done < <(list)
    echo "offsite: $newest uploaded, $(list | wc -l | tr -d ' ') on Drive"
    ;;
  list) list ;;
  get)
    name="${2:?usage: offsite.sh get <name> [dir]}"
    dir="${3:-$backups}"
    rclone copy --checksum "$remote/$name" "$dir/$name"
    echo "downloaded to $dir/$name; restore with: deploy/prod restore $dir/$name"
    ;;
  *) sed -n '2,9p' "$0"; exit 2 ;;
esac
