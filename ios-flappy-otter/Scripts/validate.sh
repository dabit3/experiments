#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mode="${1:-all}"
case "$mode" in
  all|lint|test|build) ;;
  *) echo "Usage: bash Scripts/validate.sh [all|lint|test|build]" >&2; exit 2 ;;
esac
if [[ "$mode" == all || "$mode" == lint ]]; then
  xcrun swift-format lint --strict --recursive App Core Tests AppTests Scripts Package.swift
  bash -n Scripts/validate.sh
fi
if [[ "$mode" == all || "$mode" == test ]]; then
  swift test
  xcodebuild -project FlappyOtter.xcodeproj -scheme FlappyOtter \
    -configuration Debug \
    -destination "${IOS_DESTINATION:-platform=iOS Simulator,name=iPhone 17}" \
    -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO test
elif [[ "$mode" == build ]]; then
  xcodebuild -project FlappyOtter.xcodeproj -scheme FlappyOtter \
    -configuration Debug -sdk iphonesimulator \
    -destination 'generic/platform=iOS Simulator' \
    -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO build
fi
