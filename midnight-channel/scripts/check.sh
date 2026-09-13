#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
swift format lint --strict --recursive Sources
swift format lint --strict scripts/prepare-fighters.swift
npm --prefix server run check
npm --prefix server test
npm --prefix server audit
