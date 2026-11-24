#!/usr/bin/env bash
# Pi health ping (roadmap #24), every minute via collections-health.timer. Pings the healthchecks.io
# check "raspberrypi": ok when everything is fine, fail with the reasons otherwise. If the Pi is off
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

# The site as the LAN reaches it (D-168): a running container whose host port isn't bound, or a broken proxy to the
# api, still fails here. /readyz goes through Caddy to the api and the database.
bind="$(sed -n 's/^WEB_BIND=//p' "$here/.env" 2>/dev/null | tr -d '"'"'"' \r')"
port="$(sed -n 's/^WEB_PORT=//p' "$here/.env" 2>/dev/null | tr -d '"'"'"' \r')"
url="http://${bind:-127.0.0.1}:${port:-8081}/readyz"
curl -fsS -m 10 -o /dev/null "$url" 2>/dev/null || problems+=("site not answering on $url")

if [ "${#problems[@]}" -eq 0 ]; then
  "$here/hc.sh" raspberrypi ok "disk ${disk}%, ${avail} MB free"
else
  msg="$(IFS='; '; echo "${problems[*]}")"
  echo "[health] $msg" >&2
  "$here/hc.sh" raspberrypi fail "$msg"
fi
