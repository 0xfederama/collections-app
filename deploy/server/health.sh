#!/usr/bin/env bash
# Pi health ping (roadmap #24), every 5 minutes via collection-health.timer. Pings the healthchecks.io
# check "collection-pi": ok when everything is fine, fail with the reasons otherwise. If the Pi is off
# or offline, the pings stop and healthchecks.io alerts after the grace time.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
problems=()

disk="$(df -P / | awk 'NR == 2 { gsub("%", "", $5); print $5 }')"
[ "$disk" -lt "${HEALTH_DISK_MAX:-85}" ] || problems+=("disk ${disk}% full")

avail="$(awk '/^MemAvailable:/ { print int($2 / 1024) }' /proc/meminfo)"
[ "$avail" -ge "${HEALTH_MEM_MIN_MB:-100}" ] || problems+=("only ${avail} MB memory available")

# Prod containers must be running and healthy (the test stack is not watched).
for svc in db api web; do
  state="$("$root/deploy/prod" ps --format '{{.State}} {{.Health}}' "$svc" 2>/dev/null | head -n1)"
  case "$state" in
    "running healthy" | "running ") ;;
    "") problems+=("$svc not running") ;;
    *) problems+=("$svc: $state") ;;
  esac
done

if [ "${#problems[@]}" -eq 0 ]; then
  "$here/hc.sh" collection-pi ok "disk ${disk}%, ${avail} MB free"
else
  msg="$(IFS='; '; echo "${problems[*]}")"
  echo "[health] $msg" >&2
  "$here/hc.sh" collection-pi fail "$msg"
fi
