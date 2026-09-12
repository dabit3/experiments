#!/bin/sh
# Builds the Debug Simulator app, installs it on the first available iPhone 17
# (or $UDID) and relaunches it. Usage: Scripts/sim-preview.sh [screenshot.png]
set -e
cd "$(dirname "$0")/.."
UDID=${UDID:-$(xcrun simctl list devices available | grep "iPhone 17 (" | head -1 \
  | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/')}
xcodegen generate >/dev/null
xcodebuild -project NeonBoardwalk.xcodeproj -scheme NeonBoardwalk -sdk iphonesimulator \
  -configuration Debug -derivedDataPath .build/ios CODE_SIGNING_ALLOWED=NO build -quiet
xcrun simctl boot "$UDID" 2>/dev/null || true
open -a Simulator
APP=$(find .build/ios/Build/Products/Debug-iphonesimulator -maxdepth 1 -name "*.app" | head -1)
xcrun simctl terminate "$UDID" studio.boardwalk.neon 2>/dev/null || true
xcrun simctl install "$UDID" "$APP"
xcrun simctl launch "$UDID" studio.boardwalk.neon
if [ -n "$1" ]; then
  sleep 3
  xcrun simctl io "$UDID" screenshot "$1"
fi
