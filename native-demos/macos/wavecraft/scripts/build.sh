#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
swift build --package-path "$ROOT" -c release
APP="$ROOT/dist/Wavecraft.app"
mkdir -p "$APP/Contents/MacOS"
cp "$ROOT/.build/release/Wavecraft" "$APP/Contents/MacOS/Wavecraft"
cp "$ROOT/Info.plist" "$APP/Contents/Info.plist"
codesign --force --sign - "$APP"
printf '\nBuilt %s\n' "$APP"
