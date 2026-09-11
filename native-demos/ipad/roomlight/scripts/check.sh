#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
xcrun swift-format lint --strict --recursive App Sources Tests Package.swift
swift test
./scripts/build.sh
