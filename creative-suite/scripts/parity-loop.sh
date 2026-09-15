#!/bin/bash
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MAX_CYCLES="${1:-5}"
REPAIR_RUNNER="${2:-}"
SCOPE="${3:-workspace}"
case "$SCOPE" in workspace|full) ;; *) printf 'Scope must be workspace or full.\n' >&2; exit 1;; esac
case "$MAX_CYCLES" in ''|*[!0-9]*) printf 'Cycle count must be a positive integer.\n' >&2; exit 1;; esac
if [[ "$MAX_CYCLES" -lt 1 || "$MAX_CYCLES" -gt 100 ]]; then
    printf 'Cycle count must be between 1 and 100.\n' >&2
    exit 1
fi
if [[ -n "$REPAIR_RUNNER" && ! -x "$REPAIR_RUNNER" ]]; then
    printf 'The repair runner must be an executable path, not a shell command string.\n' >&2
    exit 1
fi
mkdir -p "$ROOT/.build/parity-cycles"
LOG="$ROOT/.build/parity-cycles/loop-$$.log"
BIN="$(swift build --package-path "$ROOT" --show-bin-path)/DevinStudio"
for ((CYCLE = 1; CYCLE <= MAX_CYCLES; CYCLE++)); do
    printf '\nParity iteration %s/%s\n' "$CYCLE" "$MAX_CYCLES" | tee -a "$LOG"
    STATUS=1
    INPUT="$LOG"
    TEST_ARGS=()
    CYCLE_ARGS=(--parity-cycle "$ROOT")
    if [[ "$SCOPE" == "workspace" ]]; then TEST_ARGS=(--filter ParityAuditTests); CYCLE_ARGS+=(--workspace-only); fi
    if swift build --package-path "$ROOT" 2>&1 | tee -a "$LOG"; then
        if swift test --package-path "$ROOT" "${TEST_ARGS[@]}" 2>&1 | tee -a "$LOG"; then
            "$BIN" "${CYCLE_ARGS[@]}" 2>&1 | tee -a "$LOG"
            STATUS=${PIPESTATUS[0]}
            if [[ "$SCOPE" == "workspace" ]]; then INPUT="$ROOT/.build/parity-cycles/latest-workspace.json"; else INPUT="$ROOT/.build/parity-cycles/latest.json"; fi
        fi
    fi
    if [[ "$STATUS" -eq 0 ]]; then
        printf 'The declared reference scope passed all gates. This does not establish an unlimited feature claim.\n' | tee -a "$LOG"
        exit 0
    fi
    if [[ -z "$REPAIR_RUNNER" ]]; then
        printf 'Repair required. No repair runner is configured. Report or diagnostic log: %s\n' "$INPUT" | tee -a "$LOG"
        exit "$STATUS"
    fi
    if [[ "$CYCLE" -eq "$MAX_CYCLES" ]]; then
        printf 'Stopped at the cycle limit after verification. Parity remains unresolved.\n' | tee -a "$LOG"
        exit "$STATUS"
    fi
    if [[ ! -x "$BIN" ]]; then
        printf 'A build is required before the progress guard can run. Diagnostics: %s\n' "$LOG" >&2
        exit 1
    fi
    BEFORE="$("$BIN" --source-fingerprint "$ROOT")" || exit 1
    "$REPAIR_RUNNER" "$ROOT" "$INPUT" || exit 1
    AFTER="$("$BIN" --source-fingerprint "$ROOT")" || exit 1
    if [[ "$BEFORE" == "$AFTER" ]]; then
        printf 'Stopped: the repair runner made no source, test, or contract changes. Parity remains unresolved.\n' | tee -a "$LOG"
        exit 3
    fi
done
printf 'Stopped at the cycle limit. Unresolved features remain; no parity claim is made.\n' | tee -a "$LOG"
exit 2
