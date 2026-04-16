#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

declare -a TARGETS=(
  ".build"
  ".tmp-modulecache"
  ".artifacts"
  ".upstream"
  "CodexBar.app"
  "CodexTokenBar.app"
  "CodexTokenBar.zip"
)

print_target_size() {
  local path="$1"

  if [[ -e "$ROOT_DIR/$path" ]]; then
    du -sh "$ROOT_DIR/$path"
  else
    printf '0B\t%s\n' "$ROOT_DIR/$path"
  fi
}

echo "==> Local disk usage before cleanup"
du -sh "$ROOT_DIR"
echo ""

echo "==> Cleanup targets"
for target in "${TARGETS[@]}"; do
  print_target_size "$target"
done
echo ""

echo "==> Removing local caches and generated artifacts"
for target in "${TARGETS[@]}"; do
  rm -rf "$ROOT_DIR/$target"
done
echo "Cleanup complete."
echo ""

echo "==> Local disk usage after cleanup"
du -sh "$ROOT_DIR"
