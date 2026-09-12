#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
xcrun swift-format lint --strict --recursive Sources Tests Scripts
swift test
xcodegen generate
xcodebuild -project SugarTether.xcodeproj -scheme SugarTether \
  -sdk iphonesimulator -configuration Debug -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO build
app="build/Build/Products/Debug-iphonesimulator/SugarTether.app"
test -f "$app/Assets.car"
test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIcons:CFBundlePrimaryIcon:CFBundleIconName' "$app/Info.plist")" = "AppIcon"
