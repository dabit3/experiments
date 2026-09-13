#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
swift format lint --strict --recursive Sources
npm --prefix server run check
npm --prefix server test
npm --prefix server audit
