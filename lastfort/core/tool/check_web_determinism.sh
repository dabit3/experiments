#!/usr/bin/env bash
# Runs the deterministic simulation probe on the Dart VM and as dart2js output
# under Node, and fails if the two transcripts differ. Guards against integer
# semantics that diverge on the web (doubles above 2^53, 32-bit bit ops).
set -euo pipefail
cd "$(dirname "$0")/.."
out=$(mktemp -d)
dart run tool/determinism_probe.dart >"$out/vm.txt"
dart compile js -O2 -o "$out/probe.js" tool/determinism_probe.dart >/dev/null
node "$out/probe.js" >"$out/js.txt"
if diff "$out/vm.txt" "$out/js.txt"; then
  echo "web determinism: identical ($(wc -c <"$out/vm.txt") bytes)"
else
  echo "web determinism: VM and dart2js transcripts differ" >&2
  exit 1
fi
