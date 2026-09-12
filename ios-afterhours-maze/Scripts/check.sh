#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
xcrun swift-format lint --strict --recursive Sources Tests Scripts/GenerateIcon.swift Package.swift
swift test
xcodegen generate
xcodebuild -project AfterhoursMaze.xcodeproj -scheme AfterhoursMaze \
  -sdk iphonesimulator -configuration Debug -derivedDataPath DerivedData \
  CODE_SIGNING_ALLOWED=NO build
