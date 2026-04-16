#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
source "$HOME/Projects/agent-scripts/release/sparkle_lib.sh"

TAG=${1:-$(git describe --tags --abbrev=0)}
APP_NAME="${CODEXBAR_APP_NAME:-CodexTokenBar}"
ARTIFACT_PREFIX="${APP_NAME}-"

check_assets "$TAG" "$ARTIFACT_PREFIX"
