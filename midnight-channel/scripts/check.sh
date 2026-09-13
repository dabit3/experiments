#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
swift format lint --strict --recursive Sources
swift format lint --strict --recursive Tests
swift format lint --strict scripts/prepare-fighters.swift
npm --prefix server run check
npm --prefix server test
npm --prefix server audit
mkdir -p build
swiftc Sources/Models.swift Sources/MatchClient.swift Tests/ConnectionTests.swift -o build/connection-tests
node --check scripts/test-connection.mjs
node scripts/test-connection.mjs build/connection-tests
