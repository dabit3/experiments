#!/usr/bin/env bash
# Panic Pantry — normalized cross-platform visual parity (web reference vs native clients).
#
# Builds the web reference plus every requested native client, then hands over to
# test/visual/run.mjs which captures each screen state on both sides and compares
# them (see the header of that file for the normalization rules), and finally runs
# test/visual/selftest.mjs which proves the gate still catches injected defects.
#
# Usage:
#   test/visual-parity.sh                       # ios android macos, builds first
#   PP_PLATFORMS="macos" test/visual-parity.sh
#   PP_SKIP_BUILD=1 test/visual-parity.sh       # reuse existing builds
#
# Environment (see test/visual/run.mjs for the full list):
#   PP_PLATFORMS      space separated subset of: ios android macos (default: all three)
#   PP_STATES         space separated subset of: home lobby results (default: all three)
#   PP_IOS_UDID / PP_ANDROID_SERIAL / PP_ANDROID_SERVER / PP_JOIN_TIMEOUT
#   PP_VISUAL_BLOCK / PP_VISUAL_TOLERANCE / PP_VISUAL_SHIFT / PP_VISUAL_MAX_BLOCKS / PP_VISUAL_MAX_CORE / PP_VISUAL_MAX_CLUSTER
#   (defaults and the gate rules live in test/visual/gate.mjs)
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "$here/.." && pwd)"
export PATH="/opt/homebrew/bin:$HOME/flutter/bin:$PATH"
export LANG="${LANG:-en_US.UTF-8}"

PP_PLATFORMS="${PP_PLATFORMS:-ios android macos}"
export PP_PLATFORMS

has() { [[ " $PP_PLATFORMS " == *" $1 "* ]]; }

cd "$root"
dart pub get --directory core >/dev/null
dart pub get --directory server >/dev/null
(cd test && npm install --no-audit --no-fund >/dev/null)

if [[ "${PP_SKIP_BUILD:-0}" != "1" ]]; then
  pushd app >/dev/null
  flutter pub get >/dev/null
  flutter build web --release
  has ios && flutter build ios --simulator --debug
  has macos && flutter build macos --debug
  has android && flutter build apk --release
  popd >/dev/null
fi

node "$here/visual/run.mjs"
node "$here/visual/selftest.mjs"
