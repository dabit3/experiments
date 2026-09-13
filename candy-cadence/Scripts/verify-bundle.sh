#!/bin/bash
set -euo pipefail

if [[ $# -ne 1 || ! -d "$1" ]]; then
  echo "Usage: bash Scripts/verify-bundle.sh path/to/CandyCadence.app" >&2
  exit 1
fi

root="$(cd "$(dirname "$0")/.." && pwd)"
bundle="$1"
for source in "$root"/Resources/songs.json "$root"/Resources/*.wav; do
  name="$(basename "$source")"
  test -s "$bundle/$name"
  cmp "$source" "$bundle/$name"
  echo "Packaged resource matches source: $name"
done

test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$bundle/Info.plist")" = ai.candycadence.game
test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleDisplayName' "$bundle/Info.plist")" = "Candy Cadence"
echo "Bundle resources and application identity verified."
