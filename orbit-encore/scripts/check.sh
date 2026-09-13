#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
npm --prefix server run check
npm --prefix server test
npm --prefix server audit --audit-level=moderate
swiftlint lint --strict
xcodegen generate
xcodebuild -project OrbitEncore.xcodeproj -scheme OrbitEncore \
  -sdk iphonesimulator -configuration Debug -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO build
test -s build/Build/Products/Debug-iphonesimulator/OrbitEncore.app/Assets.car
for resource in charts.json sugar.wav neon.wav; do
  cmp "Resources/$resource" "build/Build/Products/Debug-iphonesimulator/OrbitEncore.app/$resource"
done
