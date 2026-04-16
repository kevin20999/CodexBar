#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
XCODE_APP=${XCODE_APP:-/Applications/Xcode.app}

ICTOOL="$XCODE_APP/Contents/Applications/Icon Composer.app/Contents/Executables/ictool"
if [[ ! -x "$ICTOOL" ]]; then
  ICTOOL="$XCODE_APP/Contents/Applications/Icon Composer.app/Contents/Executables/icontool"
fi
if [[ ! -x "$ICTOOL" ]]; then
  echo "ictool/icontool not found. Set XCODE_APP if Xcode is elsewhere." >&2
  exit 1
fi

build_icon() {
  local icon_file="$1"
  local basename="$2"
  local out_root="$3"
  local out_file="$4"
  local iconset_dir="$out_root/${basename}.iconset"
  local tmp_dir="$out_root/tmp"

  mkdir -p "$iconset_dir" "$tmp_dir"

  local master_art="$tmp_dir/icon_art_824.png"
  local master_1024="$tmp_dir/icon_1024.png"

  "$ICTOOL" "$icon_file" \
    --export-preview macOS Default 824 824 1 -45 "$master_art" >/dev/null

  sips --padToHeightWidth 1024 1024 "$master_art" --out "$master_1024" >/dev/null

  local sizes=(16 32 64 128 256 512 1024)
  for sz in "${sizes[@]}"; do
    local out="$iconset_dir/icon_${sz}x${sz}.png"
    sips -z "$sz" "$sz" "$master_1024" --out "$out" >/dev/null
    if [[ "$sz" -ne 1024 ]]; then
      local dbl=$((sz * 2))
      local out2="$iconset_dir/icon_${sz}x${sz}@2x.png"
      sips -z "$dbl" "$dbl" "$master_1024" --out "$out2" >/dev/null
    fi
  done

  cp "$master_1024" "$iconset_dir/icon_512x512@2x.png"
  iconutil -c icns "$iconset_dir" -o "$out_file"
  echo "Generated $out_file"
}

build_named_icon() {
  local app_name="$1"
  local icon_file=""
  case "$app_name" in
    CodexTokenBar)
      icon_file="$ROOT/AppIcons/CodexTokenBar.icon"
      ;;
    CodexDaily)
      icon_file="$ROOT/AppIcons/CodexDailyBoard.icon"
      ;;
    *)
      echo "Unknown icon target: $app_name" >&2
      exit 1
      ;;
  esac

  local out_root="$ROOT/build/icon/$app_name"
  local out_file="$out_root/Icon.icns"
  build_icon "$icon_file" "$app_name" "$out_root" "$out_file"
}

if [[ $# -eq 0 ]]; then
  build_named_icon "CodexTokenBar"
  build_named_icon "CodexDaily"
  cp "$ROOT/build/icon/CodexTokenBar/Icon.icns" "$ROOT/Icon.icns"
  exit 0
fi

case "${1:-}" in
  CodexTokenBar|CodexDaily)
    build_named_icon "$1"
    if [[ "$1" == "CodexTokenBar" ]]; then
      cp "$ROOT/build/icon/CodexTokenBar/Icon.icns" "$ROOT/Icon.icns"
    fi
    exit 0
    ;;
esac

ICON_FILE="$1"
BASENAME="${2:-Icon}"
OUT_ROOT="${3:-$ROOT/build/icon/$BASENAME}"
OUT_FILE="${4:-$OUT_ROOT/Icon.icns}"
build_icon "$ICON_FILE" "$BASENAME" "$OUT_ROOT" "$OUT_FILE"
