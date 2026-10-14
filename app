#!/usr/bin/env bash
# Whole-app launcher over compose.yaml, with two environments (variables in env/<name>.env).
#
#   ./app up                    prod (default): build and start, foreground
#   ./app up --test -d          test environment, detached
#   ./app up --test --fresh     wipe the test DB + uploaded files, then start
#   ./app down --test [--fresh] stop test (and wipe its data)
#   ./app <any compose command> [--prod|--test] [args]   e.g. ./app logs -f api --test, ./app ps
#
# --fresh is refused for prod: it deletes data.
set -euo pipefail
cd "$(dirname "$0")"

usage() { sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }

env=prod fresh=0 cmd="" args=()
for a in "$@"; do
  case "$a" in
    --prod) env=prod ;;
    --test) env=test ;;
    --fresh) fresh=1 ;;
    -h|--help) usage ;;
    *) if [ -z "$cmd" ]; then cmd="$a"; else args+=("$a"); fi ;;
  esac
done
[ -n "$cmd" ] || usage 1

[ -f backend/.env ] || { echo "missing backend/.env: cp backend/.env.example backend/.env and set POSTGRES_PASSWORD" >&2; exit 1; }
set -a; . "env/$env.env"; set +a
dc() { docker compose -p "$COMPOSE_PROJECT_NAME" "$@"; }

if [ "$fresh" = 1 ]; then
  [ "$env" = test ] || { echo "refusing --fresh on prod: it deletes data (use --test)" >&2; exit 1; }
  echo "[$env] wiping database and uploaded files"
  dc down --remove-orphans
  # Only the data volumes: the web node_modules volume is kept so the next start skips a full npm ci.
  docker volume rm -f "${COMPOSE_PROJECT_NAME}_pgdata" "${COMPOSE_PROJECT_NAME}_appdata" >/dev/null
  [ "$cmd" = down ] && exit 0
fi

case "$cmd" in
  up) echo "[$env] web http://localhost:$WEB_PORT  api http://localhost:$API_PORT"; dc up --build ${args[@]+"${args[@]}"} ;;
  *) dc "$cmd" ${args[@]+"${args[@]}"} ;;
esac
