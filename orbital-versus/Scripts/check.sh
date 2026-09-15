#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
xcrun swift-format lint --strict --recursive App Tests Scripts/NativeAudioCapture.swift
xcrun swiftc -typecheck Scripts/NativeAudioCapture.swift
npm --prefix Server run lint
npm --prefix Server test
npm --prefix Server audit --audit-level=moderate
xcodebuild -quiet -project OrbitalVersus.xcodeproj -scheme OrbitalVersus \
  -sdk iphonesimulator -configuration Debug -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath build CODE_SIGNING_ALLOWED=NO build
