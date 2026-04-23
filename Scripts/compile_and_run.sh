#!/usr/bin/env bash
# Reset the app: kill running instances, build, package, relaunch, verify.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="${CODEXBAR_APP_NAME:-CodexTokenBar}"
APP_EXECUTABLE_NAME="${CODEXBAR_EXECUTABLE_NAME:-CodexTokenBar}"
APP_BUNDLE_ID="${CODEXBAR_BUNDLE_ID:-com.kevin.codextokenbar}"
APP_BUNDLE="${CODEXBAR_INSTALL_PATH:-/Applications/${CODEXBAR_APP_BUNDLE:-${APP_NAME}.app}}"
APP_PROCESS_PATTERN="${APP_NAME}.app/Contents/MacOS/${APP_EXECUTABLE_NAME}"
DEBUG_PROCESS_PATTERN="${ROOT_DIR}/.build/debug/CodexBar"
RELEASE_PROCESS_PATTERN="${ROOT_DIR}/.build/release/CodexBar"
DAILY_BOARD_APP_NAME="${CODEXBAR_DAILY_BOARD_APP_NAME:-CodexDaily}"
DAILY_BOARD_EXECUTABLE_NAME="${CODEXBAR_DAILY_BOARD_EXECUTABLE_NAME:-CodexDaily}"
DAILY_BOARD_APP_PROCESS_PATTERN="${DAILY_BOARD_APP_NAME}.app/Contents/MacOS/${DAILY_BOARD_EXECUTABLE_NAME}"
DAILY_BOARD_DEBUG_PROCESS_PATTERN="${ROOT_DIR}/.build/debug/CodexDaily"
DAILY_BOARD_RELEASE_PROCESS_PATTERN="${ROOT_DIR}/.build/release/CodexDaily"
LEGACY_DAILY_BOARD_APP_PROCESS_PATTERN="CodexTokenBar Daily Board.app/Contents/MacOS/CodexDailyBoard"
LEGACY_DAILY_BOARD_DEBUG_PROCESS_PATTERN="${ROOT_DIR}/.build/debug/CodexDailyBoard"
LEGACY_DAILY_BOARD_RELEASE_PROCESS_PATTERN="${ROOT_DIR}/.build/release/CodexDailyBoard"
LEGACY_DAILY_BOARD_EXECUTABLE_NAME="CodexDailyBoard"
INCLUDE_DAILY="${CODEXBAR_INCLUDE_DAILY:-0}"
LOCK_KEY="$(printf '%s' "${ROOT_DIR}" | shasum -a 256 | cut -c1-8)"
LOCK_DIR="${TMPDIR:-/tmp}/codexbar-compile-and-run-${LOCK_KEY}"
LOCK_PID_FILE="${LOCK_DIR}/pid"
WAIT_FOR_LOCK=0
RUN_TESTS=0
DEBUG_LLDB=0
RELEASE_ARCHES=""
SIGNING_MODE="${CODEXBAR_SIGNING:-}"

export HOME="${CODEXBAR_HOME:-$ROOT_DIR/.home}"
export CLANG_MODULE_CACHE_PATH="${CLANG_MODULE_CACHE_PATH:-$ROOT_DIR/.build/modulecache}"
export SWIFT_MODULECACHE_PATH="${SWIFT_MODULECACHE_PATH:-$CLANG_MODULE_CACHE_PATH}"
mkdir -p "${HOME}" "${CLANG_MODULE_CACHE_PATH}"
if [[ -z "${DEVELOPER_DIR:-}" ]] && [[ -d "/Applications/Xcode.app/Contents/Developer" ]]; then
  export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
fi

log()  { printf '%s\n' "$*"; }
fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

has_signing_identity() {
  local identity="${1:-}"
  if [[ -z "${identity}" ]]; then
    return 1
  fi
  security find-identity -p codesigning -v 2>/dev/null | grep -F "${identity}" >/dev/null 2>&1
}

first_developer_id_identity() {
  security find-identity -v -p codesigning 2>/dev/null |
    sed -n 's/.*"\(Developer ID Application:[^"]*\)".*/\1/p' |
    head -n 1
}

resolve_signing_mode() {
  if [[ -n "${SIGNING_MODE}" ]]; then
    return
  fi

  local requested_identity="${CODEXBAR_SIGNING_IDENTITY:-${APP_IDENTITY:-}}"
  if [[ -n "${requested_identity}" ]]; then
    APP_IDENTITY="${requested_identity}"
    export APP_IDENTITY
    if has_signing_identity "${APP_IDENTITY}"; then
      SIGNING_MODE="identity"
      return
    fi
    log "WARN: requested signing identity not found in Keychain; falling back to adhoc signing."
    SIGNING_MODE="adhoc"
    return
  fi

  local candidate=""
  for candidate in \
    "$(first_developer_id_identity)" \
    "CodexBar Development"
  do
    if [[ -z "${candidate}" ]]; then
      continue
    fi
    if has_signing_identity "${candidate}"; then
      APP_IDENTITY="${candidate}"
      export APP_IDENTITY
      SIGNING_MODE="identity"
      return
    fi
  done

  SIGNING_MODE="adhoc"
}

run_step() {
  local label="$1"; shift
  log "==> ${label}"
  if ! "$@"; then
    fail "${label} failed"
  fi
}

cleanup() {
  if [[ -d "${LOCK_DIR}" ]]; then
    rm -rf "${LOCK_DIR}"
  fi
}

acquire_lock() {
  while true; do
    if mkdir "${LOCK_DIR}" 2>/dev/null; then
      echo "$$" > "${LOCK_PID_FILE}"
      return 0
    fi

    local existing_pid=""
    if [[ -f "${LOCK_PID_FILE}" ]]; then
      existing_pid="$(cat "${LOCK_PID_FILE}" 2>/dev/null || true)"
    fi

    if [[ -n "${existing_pid}" ]] && kill -0 "${existing_pid}" 2>/dev/null; then
      if [[ "${WAIT_FOR_LOCK}" == "1" ]]; then
        log "==> Another agent is compiling (pid ${existing_pid}); waiting..."
        while kill -0 "${existing_pid}" 2>/dev/null; do
          sleep 1
        done
        continue
      fi
      log "==> Another agent is compiling (pid ${existing_pid}); re-run with --wait."
      exit 0
    fi

    rm -rf "${LOCK_DIR}"
  done
}

trap cleanup EXIT INT TERM

kill_claude_probes() {
  # CodexBar spawns `claude /usage` + `/status` in a PTY; if we kill the app mid-probe we can orphan them.
  pkill -f "claude (/status|/usage) --allowed-tools" 2>/dev/null || true
  sleep 0.2
  pkill -9 -f "claude (/status|/usage) --allowed-tools" 2>/dev/null || true
}

kill_all_codexbar() {
  is_running() {
    if pgrep -f "${APP_PROCESS_PATTERN}" >/dev/null 2>&1 \
      || pgrep -f "${DEBUG_PROCESS_PATTERN}" >/dev/null 2>&1 \
      || pgrep -f "${RELEASE_PROCESS_PATTERN}" >/dev/null 2>&1 \
      || pgrep -x "${APP_EXECUTABLE_NAME}" >/dev/null 2>&1
    then
      return 0
    fi

    if [[ "${INCLUDE_DAILY}" == "1" ]]; then
      if pgrep -f "${DAILY_BOARD_APP_PROCESS_PATTERN}" >/dev/null 2>&1 \
        || pgrep -f "${DAILY_BOARD_DEBUG_PROCESS_PATTERN}" >/dev/null 2>&1 \
        || pgrep -f "${DAILY_BOARD_RELEASE_PROCESS_PATTERN}" >/dev/null 2>&1 \
        || pgrep -x "${DAILY_BOARD_EXECUTABLE_NAME}" >/dev/null 2>&1 \
        || pgrep -f "${LEGACY_DAILY_BOARD_APP_PROCESS_PATTERN}" >/dev/null 2>&1 \
        || pgrep -f "${LEGACY_DAILY_BOARD_DEBUG_PROCESS_PATTERN}" >/dev/null 2>&1 \
        || pgrep -f "${LEGACY_DAILY_BOARD_RELEASE_PROCESS_PATTERN}" >/dev/null 2>&1 \
        || pgrep -x "${LEGACY_DAILY_BOARD_EXECUTABLE_NAME}" >/dev/null 2>&1
      then
        return 0
      fi
    fi

    return 1
  }

  # Phase 1: request termination (give the app time to exit cleanly).
  for _ in {1..25}; do
    pkill -f "${APP_PROCESS_PATTERN}" 2>/dev/null || true
    pkill -f "${DEBUG_PROCESS_PATTERN}" 2>/dev/null || true
    pkill -f "${RELEASE_PROCESS_PATTERN}" 2>/dev/null || true
    pkill -x "${APP_EXECUTABLE_NAME}" 2>/dev/null || true
    if [[ "${INCLUDE_DAILY}" == "1" ]]; then
      pkill -f "${DAILY_BOARD_APP_PROCESS_PATTERN}" 2>/dev/null || true
      pkill -f "${DAILY_BOARD_DEBUG_PROCESS_PATTERN}" 2>/dev/null || true
      pkill -f "${DAILY_BOARD_RELEASE_PROCESS_PATTERN}" 2>/dev/null || true
      pkill -x "${DAILY_BOARD_EXECUTABLE_NAME}" 2>/dev/null || true
      pkill -f "${LEGACY_DAILY_BOARD_APP_PROCESS_PATTERN}" 2>/dev/null || true
      pkill -f "${LEGACY_DAILY_BOARD_DEBUG_PROCESS_PATTERN}" 2>/dev/null || true
      pkill -f "${LEGACY_DAILY_BOARD_RELEASE_PROCESS_PATTERN}" 2>/dev/null || true
      pkill -x "${LEGACY_DAILY_BOARD_EXECUTABLE_NAME}" 2>/dev/null || true
    fi
    if ! is_running; then
      return 0
    fi
    sleep 0.2
  done

  # Phase 2: force kill any stragglers (avoids `open -n` creating multiple instances).
  pkill -9 -f "${APP_PROCESS_PATTERN}" 2>/dev/null || true
  pkill -9 -f "${DEBUG_PROCESS_PATTERN}" 2>/dev/null || true
  pkill -9 -f "${RELEASE_PROCESS_PATTERN}" 2>/dev/null || true
  pkill -9 -x "${APP_EXECUTABLE_NAME}" 2>/dev/null || true
  if [[ "${INCLUDE_DAILY}" == "1" ]]; then
    pkill -9 -f "${DAILY_BOARD_APP_PROCESS_PATTERN}" 2>/dev/null || true
    pkill -9 -f "${DAILY_BOARD_DEBUG_PROCESS_PATTERN}" 2>/dev/null || true
    pkill -9 -f "${DAILY_BOARD_RELEASE_PROCESS_PATTERN}" 2>/dev/null || true
    pkill -9 -x "${DAILY_BOARD_EXECUTABLE_NAME}" 2>/dev/null || true
    pkill -9 -f "${LEGACY_DAILY_BOARD_APP_PROCESS_PATTERN}" 2>/dev/null || true
    pkill -9 -f "${LEGACY_DAILY_BOARD_DEBUG_PROCESS_PATTERN}" 2>/dev/null || true
    pkill -9 -f "${LEGACY_DAILY_BOARD_RELEASE_PROCESS_PATTERN}" 2>/dev/null || true
    pkill -9 -x "${LEGACY_DAILY_BOARD_EXECUTABLE_NAME}" 2>/dev/null || true
  fi

  for _ in {1..25}; do
    if ! is_running; then
      return 0
    fi
    sleep 0.2
  done

  fail "Failed to kill all ${APP_NAME} instances."
}

# 1) Ensure a single runner instance.
for arg in "$@"; do
  case "${arg}" in
    --wait|-w) WAIT_FOR_LOCK=1 ;;
    --test|-t) RUN_TESTS=1 ;;
    --debug-lldb) DEBUG_LLDB=1 ;;
    --release-universal) RELEASE_ARCHES="arm64 x86_64" ;;
    --release-arches=*) RELEASE_ARCHES="${arg#*=}" ;;
    --help|-h)
      log "Usage: $(basename "$0") [--wait] [--test] [--debug-lldb] [--release-universal] [--release-arches=\"arm64 x86_64\"]"
      exit 0
      ;;
    *)
      ;;
  esac
done

resolve_signing_mode
if [[ "${SIGNING_MODE}" == "adhoc" ]]; then
  log "==> Signing: adhoc (set APP_IDENTITY or install a dev cert to avoid keychain prompts)"
else
  log "==> Signing: ${APP_IDENTITY:-Developer ID Application}"
fi

acquire_lock

# 2) Kill all running instances (debug, release, bundled).
log "==> Killing existing ${APP_NAME} instances"
kill_all_codexbar
kill_claude_probes

# 2.5) Delete keychain entries to avoid permission prompts with adhoc signing
# (adhoc signature changes on every build, making old keychain entries inaccessible)
if [[ "${SIGNING_MODE:-adhoc}" == "adhoc" ]]; then
  log "==> Clearing keychain entries (adhoc signing)"
  security delete-generic-password -s "${APP_BUNDLE_ID}" 2>/dev/null || true
  # Clear all keychain items for the app to avoid multiple prompts
  while security delete-generic-password -s "${APP_BUNDLE_ID}" 2>/dev/null; do
    :
  done
fi

# 3) Package (release build happens inside package_app.sh).
if [[ "${RUN_TESTS}" == "1" ]]; then
  run_step "swift test" swift test -q
fi
if [[ "${DEBUG_LLDB}" == "1" && -n "${RELEASE_ARCHES}" ]]; then
  fail "--release-arches is only supported for release packaging"
fi
HOST_ARCH="$(uname -m)"
ARCHES_VALUE="${HOST_ARCH}"
if [[ -n "${RELEASE_ARCHES}" ]]; then
  ARCHES_VALUE="${RELEASE_ARCHES}"
fi
if [[ "${DEBUG_LLDB}" == "1" ]]; then
  run_step "package app" env CODEXBAR_ALLOW_LLDB=1 CODEXBAR_PACKAGE_DAILY_APP="${INCLUDE_DAILY}" ARCHES="${ARCHES_VALUE}" "${ROOT_DIR}/Scripts/package_app.sh" debug
else
  if [[ -n "${SIGNING_MODE}" ]]; then
    run_step "package app" env CODEXBAR_SIGNING="${SIGNING_MODE}" CODEXBAR_PACKAGE_DAILY_APP="${INCLUDE_DAILY}" ARCHES="${ARCHES_VALUE}" "${ROOT_DIR}/Scripts/package_app.sh"
  else
    run_step "package app" env CODEXBAR_PACKAGE_DAILY_APP="${INCLUDE_DAILY}" ARCHES="${ARCHES_VALUE}" "${ROOT_DIR}/Scripts/package_app.sh"
  fi
fi

# 4) Launch the packaged app.
log "==> launch app"
if ! open "${APP_BUNDLE}"; then
  log "WARN: launch app returned non-zero; falling back to direct binary launch."
  "${APP_BUNDLE}/Contents/MacOS/${APP_EXECUTABLE_NAME}" >/dev/null 2>&1 &
  disown
fi

# 5) Verify the app stays up for at least a moment (launch can be >1s on some systems).
for _ in {1..10}; do
  if pgrep -f "${APP_PROCESS_PATTERN}" >/dev/null 2>&1; then
    log "OK: ${APP_NAME} is running."
    exit 0
  fi
  sleep 0.4
done
fail "App exited immediately. Check crash logs in Console.app (User Reports)."
