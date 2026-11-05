#!/usr/bin/env bash
# Alerts via healthchecks.io (roadmap #24). healthchecks.io sends the email/push, the Pi never sends mail.
#
#   hc.sh <check> ok|fail|start [message]   ping one check; also accepts a systemd $SERVICE_RESULT
#                                           (success = ok, anything else = fail)
#
# Checks are created on first ping (slug URLs with ?create=1) under the project of HC_PING_KEY
# (deploy/server/.env). Without HC_PING_KEY this does nothing. Never fails its caller.
here="$(cd "$(dirname "$0")" && pwd)"
if [ -z "${HC_PING_KEY:-}" ] && [ -f "$here/.env" ]; then
  HC_PING_KEY="$(sed -n 's/^HC_PING_KEY=//p' "$here/.env" | tr -d '"'"'"' \r')"
fi
[ -n "${HC_PING_KEY:-}" ] || exit 0
check="${1:?check slug}"; kind="${2:-ok}"; msg="${3:-}"
case "$kind" in
  ok | success) suffix="" ;;
  start) suffix="/start" ;;
  *) suffix="/fail"; [ -n "$msg" ] || msg="result: $kind" ;;
esac
curl -fsS -m 10 --retry 3 -o /dev/null --data-raw "$(hostname): ${msg:-ok}" \
  "https://hc-ping.com/$HC_PING_KEY/$check$suffix?create=1" || echo "[hc] ping $check$suffix failed" >&2
exit 0
