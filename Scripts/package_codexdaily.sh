#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

exec env \
  CODEXBAR_SIGNING="${CODEXBAR_SIGNING:-adhoc}" \
  CODEXBAR_PACKAGE_MAIN_APP=0 \
  CODEXBAR_PACKAGE_DAILY_APP=1 \
  "${ROOT_DIR}/Scripts/package_app.sh" "$@"
