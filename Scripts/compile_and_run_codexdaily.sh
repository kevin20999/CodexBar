#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="CodexDaily"
APP_EXECUTABLE_NAME="CodexDaily"
APP_BUNDLE="/Applications/${APP_NAME}.app"
APP_PROCESS_PATTERN="${APP_NAME}.app/Contents/MacOS/${APP_EXECUTABLE_NAME}"
DEBUG_PROCESS_PATTERN="${ROOT_DIR}/.build/debug/${APP_EXECUTABLE_NAME}"
RELEASE_PROCESS_PATTERN="${ROOT_DIR}/.build/release/${APP_EXECUTABLE_NAME}"
RUN_TESTS=0

log()  { printf '%s\n' "$*"; }
fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

for arg in "$@"; do
  case "${arg}" in
    --test|-t) RUN_TESTS=1 ;;
    --help|-h)
      log "Usage: $(basename "$0") [--test]"
      exit 0
      ;;
  esac
done

kill_codexdaily() {
  pkill -f "${APP_PROCESS_PATTERN}" 2>/dev/null || true
  pkill -f "${DEBUG_PROCESS_PATTERN}" 2>/dev/null || true
  pkill -f "${RELEASE_PROCESS_PATTERN}" 2>/dev/null || true
  pkill -x "${APP_EXECUTABLE_NAME}" 2>/dev/null || true
  sleep 0.2
  pkill -9 -f "${APP_PROCESS_PATTERN}" 2>/dev/null || true
  pkill -9 -f "${DEBUG_PROCESS_PATTERN}" 2>/dev/null || true
  pkill -9 -f "${RELEASE_PROCESS_PATTERN}" 2>/dev/null || true
  pkill -9 -x "${APP_EXECUTABLE_NAME}" 2>/dev/null || true
}

log "==> Killing existing ${APP_NAME} instances"
kill_codexdaily

if [[ "${RUN_TESTS}" == "1" ]]; then
  log "==> swift test"
  swift test -q
fi

log "==> Packaging ${APP_NAME}"
"${ROOT_DIR}/Scripts/package_codexdaily.sh"

log "==> Launching ${APP_NAME}"
if ! open "${APP_BUNDLE}"; then
  log "WARN: open failed; falling back to direct launch."
  "${APP_BUNDLE}/Contents/MacOS/${APP_EXECUTABLE_NAME}" >/dev/null 2>&1 &
  disown
fi

for _ in {1..10}; do
  if pgrep -f "${APP_PROCESS_PATTERN}" >/dev/null 2>&1; then
    log "OK: ${APP_NAME} is running."
    exit 0
  fi
  sleep 0.4
done

fail "${APP_NAME} exited immediately. Check crash logs in Console.app."
