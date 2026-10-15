# shellcheck shell=bash
# Shared by deploy/dev, deploy/test and deploy/prod. Source it after `set -euo pipefail` and setting ENV_NAME.

DEPLOY="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(dirname "$DEPLOY")"

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  BOLD=$'\e[1m' DIM=$'\e[2m' RED=$'\e[31m' GREEN=$'\e[32m' CYAN=$'\e[36m' RESET=$'\e[0m'
else
  BOLD='' DIM='' RED='' GREEN='' CYAN='' RESET=''
fi

say() { printf '%s\n' "${CYAN}${BOLD}[$ENV_NAME]${RESET} $*"; }
ok() { printf '%s\n' "${GREEN}${BOLD}[$ENV_NAME]${RESET} $*"; }
die() {
  printf '%s\n' "${RED}${BOLD}[$ENV_NAME] error:${RESET} $*" >&2
  exit 1
}

# The calling script's header comment is its help text.
usage() {
  awk 'NR == 1 { next } /^#/ { sub(/^# ?/, ""); print; next } { exit }' "$0"
  exit "${1:-0}"
}

need_file() { [ -f "$1" ] || die "missing ${1#"$ROOT"/}: $2"; }

# Export every KEY=VALUE of an env file (quote values that contain spaces).
load_env() {
  set -a
  # shellcheck disable=SC1090
  . "$1"
  set +a
}

# dev and test: the local stack (backend + Vite dev server) with deploy/local/<env>.env.
# Secrets stay in backend/.env (gitignored); the env file sets project name, ports and settings.
use_local_stack() {
  need_file "$ROOT/backend/.env" "cp backend/.env.example backend/.env and set POSTGRES_PASSWORD"
  load_env "$DEPLOY/local/$ENV_NAME.env"
  export COMPOSE_FILE="$DEPLOY/local/compose.yaml"
}

# Pass a compose command through; `up` always rebuilds the api image and prints where the app is.
run_local() {
  local cmd="${1:-}"
  case "$cmd" in
    "" ) usage 1 ;;
    -h | --help | help) usage ;;
  esac
  shift
  if [ "$cmd" = up ]; then
    say "web ${BOLD}http://localhost:$WEB_PORT${RESET}   api http://localhost:$API_PORT   ${DIM}(project $COMPOSE_PROJECT_NAME)${RESET}"
    docker compose up --build "$@"
  else
    docker compose "$cmd" "$@"
  fi
}
