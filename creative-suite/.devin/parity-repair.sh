#!/bin/bash
set -euo pipefail
ROOT="${1:?Repository path is required}"
REPORT="${2:?Audit report or log path is required}"
FOCUS="${PARITY_REPAIR_FOCUS:-Repair one documented failure in document tabs or native grouped-menu controls. Do not edit the Pixel tool engine or its tests, which another agent owns.}"
case "$REPORT" in "$ROOT"/.build/parity-cycles/*) ;; *) printf 'The repair report must be inside this repository audit directory.\n' >&2; exit 1;; esac
command -v devin >/dev/null || { printf 'Devin CLI is required for the repair worker.\n' >&2; exit 1; }
cd "$ROOT"
exec devin --permission-mode normal --export "$ROOT/.build/parity-cycles/worker-$(date +%s)-$$.json" --print "Read $ROOT/.devin/parity-worker-instructions.txt and obey it. Repository: $ROOT. Current audit report or log: $REPORT. Focus for this pass: $FOCUS. Complete one coherent repair pass, verify it, and report the result. Do not change audit gates, reference contracts, permissions, or packaged apps."
