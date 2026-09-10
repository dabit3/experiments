#!/usr/bin/env bash
# Panic Pantry — web navigation/state smoke test (home, how-to-play, join
# errors, host/leave, theme). Builds the web client unless PP_SKIP_BUILD=1,
# then runs test/ui/smoke.mjs; evidence lands in
# .devin/clone-this/panic-pantry/evidence/tests/ui-smoke/.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "$here/.." && pwd)"
export PATH="/opt/homebrew/bin:$HOME/flutter/bin:$PATH"
export LANG="${LANG:-en_US.UTF-8}"

cd "$root"
dart pub get --directory core >/dev/null
dart pub get --directory server >/dev/null
(cd test && npm install --no-audit --no-fund >/dev/null)

if [[ "${PP_SKIP_BUILD:-0}" != "1" ]]; then
  (cd app && flutter pub get >/dev/null && flutter build web --release)
fi

node "$here/ui/smoke.mjs"
