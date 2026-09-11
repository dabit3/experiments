#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
swift format lint --strict --recursive Sources Tests Package.swift
swift test
swift build -c release -Xswiftc -warnings-as-errors
plutil -lint Info.plist
