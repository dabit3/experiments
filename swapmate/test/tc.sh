#!/usr/bin/env bash
# tc.sh <testId> '<json command>' [timeoutMs]  — send a test command via the server.
set -euo pipefail
SERVER="${SWAPMATE_HTTP:-http://localhost:8787}"
curl -sS -X POST "$SERVER/test/command" -H 'content-type: application/json' \
  -d "{\"testId\":\"$1\",\"command\":$2,\"timeoutMs\":${3:-20000}}"
echo
