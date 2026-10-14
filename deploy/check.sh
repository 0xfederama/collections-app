#!/usr/bin/env bash
# AT-18 for production: every published port in the rendered prod compose must bind 127.0.0.1,
# except the web port when WEB_BIND names a specific other address (explicit opt-in).
# 0.0.0.0, :: or an empty bind (= all interfaces) always fails.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"

# Values from deploy/.env, unless already in the environment (so tests can override WEB_BIND).
if [ -f "$here/.env" ]; then
  while IFS='=' read -r key value; do
    if [ -z "${!key:-}" ]; then export "$key=$value"; fi
  done < <(grep -E '^(WEB_BIND|WEB_PORT)=' "$here/.env" || true)
fi

rendered="$(POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-check}" docker compose -f "$here/compose.prod.yaml" config --format json)"

bad=0
while IFS=$'\t' read -r service host_ip published; do
  case "$host_ip" in
    127.0.0.1 | ::1) ;;
    "" | 0.0.0.0 | :: | null)
      echo "FAIL: $service publishes port $published on all interfaces" >&2
      bad=1
      ;;
    *)
      if [ "$service" = web ] && [ "${WEB_BIND:-127.0.0.1}" = "$host_ip" ]; then
        echo "note: web published on $host_ip:$published by explicit opt-in (WEB_BIND)"
      else
        echo "FAIL: $service publishes port $published on $host_ip without opt-in" >&2
        bad=1
      fi
      ;;
  esac
done < <(jq -r '.services | to_entries[] | .key as $s | (.value.ports // [])[] | [$s, (.host_ip // ""), .published] | @tsv' <<<"$rendered")

[ "$bad" = 0 ] || exit 1
count="$(jq '[.services[].ports // [] | length] | add' <<<"$rendered")"
echo "prod compose exposure ok ($count published port(s))"
