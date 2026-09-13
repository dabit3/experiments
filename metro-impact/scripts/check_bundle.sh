#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="${1:-$ROOT/.build/Build/Products/Debug-iphonesimulator/MetroImpact.app}"
count=0
for source in "$ROOT"/Assets/*; do
  bundled="$APP/Assets/$(basename "$source")"
  if ! cmp -s "$source" "$bundled"; then
    printf 'Missing or stale bundled asset: %s\n' "$bundled" >&2
    exit 1
  fi
  count=$((count + 1))
done
printf 'Verified %s bundled game assets in %s\n' "$count" "$APP"
