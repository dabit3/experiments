#!/usr/bin/env bash
# Runs the Brickfolk four-platform multiplayer test.
#
#   ./test/multiplayer-e2e.sh                      # build + run web, iOS, Android, macOS
#   ./test/multiplayer-e2e.sh --no-build           # reuse builds from an earlier harness run
#                                                  # (iOS/Android bake the test config in at build time)
#   ./test/multiplayer-e2e.sh --platforms web,macos
#
# Requirements: Flutter, Xcode + an iOS simulator, Android SDK with an AVD
# (the harness boots it when no device is online), Node 20+, ffmpeg.
# Evidence (screenshots, recordings, logs, report.json) lands under
# .devin/clone-this/brickfolk/evidence/tests/multiplayer-<timestamp>/.
#
# Emulator overrides: BRICKFOLK_EMULATOR (binary), BRICKFOLK_AVD (name),
# BRICKFOLK_EMULATOR_ARGS (extra flags). On Macs without Hypervisor.framework
# (e.g. virtualised CI hosts) the arm64 emulator cannot use HVF; if a legacy
# emulator with TCG support is installed under ~/android-legacy it is used
# automatically with software acceleration.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export ANDROID_HOME="${ANDROID_HOME:-/opt/homebrew/share/android-commandlinetools}"
export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-$ANDROID_HOME}"
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH"

if [ "$(uname -s)" = "Darwin" ] && [ "$(sysctl -n kern.hv_support 2>/dev/null || echo 1)" = "0" ] \
   && [ -z "${BRICKFOLK_EMULATOR:-}" ] && [ -x "$HOME/android-legacy/emulator/emulator" ]; then
  export BRICKFOLK_EMULATOR="$HOME/android-legacy/emulator/emulator"
  export BRICKFOLK_AVD="${BRICKFOLK_AVD:-brickfolk_legacy}"
  export BRICKFOLK_EMULATOR_ARGS="${BRICKFOLK_EMULATOR_ARGS:--accel off -no-window}"
fi

cd "$ROOT/test/e2e"
if [ ! -d node_modules/playwright ]; then
  npm install --no-audit --no-fund
  npx playwright install chromium
fi

cd "$ROOT/shared" && dart pub get >/dev/null
cd "$ROOT/server" && dart pub get >/dev/null
cd "$ROOT/app" && flutter pub get >/dev/null

cd "$ROOT/test/e2e"
exec node run.mjs "$@"
