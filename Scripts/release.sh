#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"

source "$ROOT/version.env"
source "$HOME/Projects/agent-scripts/release/sparkle_lib.sh"

resolve_release_repo() {
  if [[ -n "${CODEXBAR_RELEASE_REPO:-}" ]]; then
    printf '%s\n' "$CODEXBAR_RELEASE_REPO"
    return 0
  fi

  local remote_url
  remote_url=$(git remote get-url origin 2>/dev/null || true)
  case "$remote_url" in
    https://github.com/*)
      remote_url="${remote_url#https://github.com/}"
      remote_url="${remote_url%.git}"
      printf '%s\n' "$remote_url"
      return 0
      ;;
    git@github.com:*)
      remote_url="${remote_url#git@github.com:}"
      remote_url="${remote_url%.git}"
      printf '%s\n' "$remote_url"
      return 0
      ;;
  esac
  return 1
}

APPCAST="$ROOT/appcast.xml"
APP_NAME="${CODEXBAR_APP_NAME:-CodexTokenBar}"
ARTIFACT_PREFIX="${APP_NAME}-"
BUNDLE_ID="${CODEXBAR_BUNDLE_ID:-com.kevin.codextokenbar}"
RELEASE_REPO="$(resolve_release_repo || true)"
APPCAST_BRANCH="${CODEXBAR_APPCAST_BRANCH:-main}"
APPCAST_FEED_URL="${CODEXBAR_APPCAST_FEED_URL:-}"
TAG="v${MARKETING_VERSION}"

if [[ -z "$APPCAST_FEED_URL" && -n "$RELEASE_REPO" ]]; then
  APPCAST_FEED_URL="https://raw.githubusercontent.com/${RELEASE_REPO}/${APPCAST_BRANCH}/appcast.xml"
fi

err() { echo "ERROR: $*" >&2; exit 1; }

require_clean_worktree
ensure_changelog_finalized "$MARKETING_VERSION"
ensure_appcast_monotonic "$APPCAST" "$MARKETING_VERSION" "$BUILD_NUMBER"

if [[ -z "$APPCAST_FEED_URL" ]]; then
  err "Could not infer appcast feed URL. Set CODEXBAR_APPCAST_FEED_URL or CODEXBAR_RELEASE_REPO."
fi

swiftformat Sources Tests >/dev/null
swiftlint --strict
swift test

# Note: run this script in the foreground; do not background it so it waits to completion.
"$ROOT/Scripts/sign-and-notarize.sh"

KEY_FILE=$(clean_key "$SPARKLE_PRIVATE_KEY_FILE")
trap 'rm -f "$KEY_FILE"' EXIT

probe_sparkle_key "$KEY_FILE"

clear_sparkle_caches "$BUNDLE_ID"

NOTES_FILE=$(mktemp /tmp/codextokenbar-notes.XXXXXX.md)
extract_notes_from_changelog "$MARKETING_VERSION" "$NOTES_FILE"
trap 'rm -f "$KEY_FILE" "$NOTES_FILE"' EXIT

git tag -f "$TAG"
git push -f origin "$TAG"

gh release create "$TAG" ${APP_NAME}-${MARKETING_VERSION}.zip ${APP_NAME}-${MARKETING_VERSION}.dSYM.zip \
  --title "${APP_NAME} ${MARKETING_VERSION}" \
  --notes-file "$NOTES_FILE"

SPARKLE_PRIVATE_KEY_FILE="$KEY_FILE" \
  "$ROOT/Scripts/make_appcast.sh" \
  "${APP_NAME}-${MARKETING_VERSION}.zip" \
  "$APPCAST_FEED_URL"

verify_appcast_entry "$APPCAST" "$MARKETING_VERSION" "$KEY_FILE"

git add "$APPCAST"
git commit -m "docs: update appcast for ${MARKETING_VERSION}"
git push origin main

if [[ "${RUN_SPARKLE_UPDATE_TEST:-0}" == "1" ]]; then
  PREV_TAG=$(git tag --sort=-v:refname | sed -n '2p')
  [[ -z "$PREV_TAG" ]] && err "RUN_SPARKLE_UPDATE_TEST=1 set but no previous tag found"
  "$ROOT/Scripts/test_live_update.sh" "$PREV_TAG" "v${MARKETING_VERSION}"
fi

check_assets "$TAG" "$ARTIFACT_PREFIX"

git push origin --tags

echo "Release ${MARKETING_VERSION} complete."
