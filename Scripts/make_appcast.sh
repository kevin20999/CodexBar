#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
APP_NAME="${CODEXBAR_APP_NAME:-CodexTokenBar}"

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

ZIP=${1:?
"Usage: $0 ${APP_NAME}-<ver>.zip"}
RELEASE_REPO="$(resolve_release_repo || true)"
APPCAST_BRANCH="${CODEXBAR_APPCAST_BRANCH:-main}"
FEED_URL=${2:-${CODEXBAR_APPCAST_FEED_URL:-}}
PRIVATE_KEY_FILE=${SPARKLE_PRIVATE_KEY_FILE:-}
SPARKLE_CHANNEL=${SPARKLE_CHANNEL:-}

if [[ -z "$FEED_URL" && -n "$RELEASE_REPO" ]]; then
  FEED_URL="https://raw.githubusercontent.com/${RELEASE_REPO}/${APPCAST_BRANCH}/appcast.xml"
fi
if [[ -z "$PRIVATE_KEY_FILE" ]]; then
  echo "Set SPARKLE_PRIVATE_KEY_FILE to your ed25519 private key (Sparkle)." >&2
  exit 1
fi
if [[ ! -f "$ZIP" ]]; then
  echo "Zip not found: $ZIP" >&2
  exit 1
fi

ZIP_DIR=$(cd "$(dirname "$ZIP")" && pwd)
ZIP_NAME=$(basename "$ZIP")
ZIP_BASE="${ZIP_NAME%.zip}"
VERSION=${SPARKLE_RELEASE_VERSION:-}
if [[ -z "$VERSION" ]]; then
  local_prefix="${APP_NAME}-"
  if [[ "$ZIP_NAME" == "${local_prefix}"*.zip ]]; then
    VERSION="${ZIP_NAME#${local_prefix}}"
    VERSION="${VERSION%.zip}"
  else
    echo "Could not infer version from $ZIP_NAME; set SPARKLE_RELEASE_VERSION." >&2
    exit 1
  fi
fi

NOTES_HTML="${ZIP_DIR}/${ZIP_BASE}.html"
KEEP_NOTES=${KEEP_SPARKLE_NOTES:-0}
if [[ -x "$ROOT/Scripts/changelog-to-html.sh" ]]; then
  "$ROOT/Scripts/changelog-to-html.sh" "$VERSION" >"$NOTES_HTML"
else
  echo "Missing Scripts/changelog-to-html.sh; cannot generate HTML release notes." >&2
  exit 1
fi
if [[ -z "$FEED_URL" ]]; then
  echo "Could not infer feed URL. Pass it as the second argument or set CODEXBAR_APPCAST_FEED_URL." >&2
  exit 1
fi
cleanup() {
  if [[ -n "${WORK_DIR:-}" ]]; then
    rm -rf "$WORK_DIR"
  fi
  if [[ "$KEEP_NOTES" != "1" ]]; then
    rm -f "$NOTES_HTML"
  fi
}
trap cleanup EXIT

DOWNLOAD_URL_PREFIX=${SPARKLE_DOWNLOAD_URL_PREFIX:-}
if [[ -z "$DOWNLOAD_URL_PREFIX" && -n "$RELEASE_REPO" ]]; then
  DOWNLOAD_URL_PREFIX="https://github.com/${RELEASE_REPO}/releases/download/v${VERSION}/"
fi
if [[ -z "$DOWNLOAD_URL_PREFIX" ]]; then
  echo "Could not infer download URL prefix. Set SPARKLE_DOWNLOAD_URL_PREFIX or CODEXBAR_RELEASE_REPO." >&2
  exit 1
fi

# Sparkle provides generate_appcast; ensure it's on PATH (via SwiftPM build of Sparkle's bin) or Xcode dmg
if ! command -v generate_appcast >/dev/null; then
  echo "generate_appcast not found in PATH. Install Sparkle tools (see Sparkle docs)." >&2
  exit 1
fi

WORK_DIR=$(mktemp -d /tmp/codextokenbar-appcast.XXXXXX)

cp "$ROOT/appcast.xml" "$WORK_DIR/appcast.xml"
cp "$ZIP" "$WORK_DIR/$ZIP_NAME"
cp "$NOTES_HTML" "$WORK_DIR/$ZIP_BASE.html"

pushd "$WORK_DIR" >/dev/null
generate_appcast \
  --ed-key-file "$PRIVATE_KEY_FILE" \
  --download-url-prefix "$DOWNLOAD_URL_PREFIX" \
  --embed-release-notes \
  --link "$FEED_URL" \
  "$WORK_DIR"
popd >/dev/null

if [[ -n "$SPARKLE_CHANNEL" ]]; then
  python3 - "$WORK_DIR/appcast.xml" "$VERSION" "$SPARKLE_CHANNEL" <<'PY'
import re
import sys

path, version, channel = sys.argv[1], sys.argv[2], sys.argv[3]
with open(path, "r", encoding="utf-8") as handle:
    lines = handle.read().splitlines()

target = f"<sparkle:shortVersionString>{version}</sparkle:shortVersionString>"
try:
    index = next(i for i, line in enumerate(lines) if target in line)
except StopIteration as exc:
    raise SystemExit(f"Could not find {target} in {path}") from exc

for j in range(index, -1, -1):
    if "<item" in lines[j]:
        line = lines[j]
        if "sparkle:channel" in line:
            line = re.sub(r'sparkle:channel="[^"]*"', f'sparkle:channel="{channel}"', line)
        else:
            line = line.replace("<item", f'<item sparkle:channel="{channel}"', 1)
        lines[j] = line
        break
else:
    raise SystemExit(f"Could not find <item> for version {version} in {path}")

with open(path, "w", encoding="utf-8") as handle:
    handle.write("\n".join(lines) + "\n")
PY
  echo "Tagged ${VERSION} with sparkle:channel=\"${SPARKLE_CHANNEL}\""
fi

cp "$WORK_DIR/appcast.xml" "$ROOT/appcast.xml"

echo "Appcast generated (appcast.xml). Upload alongside $ZIP at $FEED_URL"
