#!/bin/bash
set -euo pipefail
APP_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$APP_ROOT"
swift build -c release
mkdir -p dist/Railway.app/Contents/MacOS
cp .build/release/Railway dist/Railway.app/Contents/MacOS/Railway
cp Info.plist dist/Railway.app/Contents/Info.plist
codesign --force --sign - dist/Railway.app
echo "Built $APP_ROOT/dist/Railway.app"
