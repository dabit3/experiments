#!/usr/bin/env bash
# Panic Pantry — automated four-way multiplayer match (web + iOS + Android + macOS).
#
# Builds every requested client, then hands over to test/e2e/run.mjs which starts
# the authoritative server, launches the clients, joins them to one room, replays a
# deterministic input script through the server's test channel, captures
# screenshots + a screen recording and asserts that every client reports the
# identical final score and star rating.
#
# Usage:
#   test/multiplayer-e2e.sh                 # all four platforms, builds first
#   PP_PLATFORMS="web macos" test/multiplayer-e2e.sh
#   PP_SKIP_BUILD=1 test/multiplayer-e2e.sh # reuse existing builds
#
# Environment:
#   PP_PLATFORMS            space separated subset of: web ios android macos (default: all)
#   PP_OPTIONAL_PLATFORMS   platforms whose absence is recorded but does not fail the run
#   PP_ROOM / PP_SEED / PP_LEVEL / PP_SPEED   room code, deterministic seed, level id, sim speed
#   PP_PORT / PP_WEB_PORT   server port (8787) and static web port (8080)
#   PP_EVIDENCE_DIR         output directory (default: .devin/clone-this/panic-pantry/evidence/e2e/<timestamp>)
#   PP_IOS_UDID             simulator to use (default: a booted simulator, else the first iPhone)
#   PP_ANDROID_AVD          AVD to boot when no device is attached (default: panic_pantry)
#   PP_ANDROID_SERIAL       use an already attached device/emulator (e.g. emulator-5554, 127.0.0.1:5555)
#   PP_ANDROID_SERVER       server URL as seen from the Android device (default: ws://10.0.2.2:$PP_PORT/ws)
#   PP_ANDROID_WINDOW       macOS process owning the emulator window, for tiling (default: qemu-system-aarch64)
#   PP_JOIN_TIMEOUT         seconds to wait for every client to join/answer (default: 150)
#   PP_RECORD=0             disable the screen recording
#   PP_REVIEW_VIDEO=0       skip cutting the edited review video after the run (test/review-video.sh)
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "$here/.." && pwd)"
export PATH="/opt/homebrew/bin:$HOME/flutter/bin:$PATH"
export LANG="${LANG:-en_US.UTF-8}"

PP_PLATFORMS="${PP_PLATFORMS:-web ios android macos}"
PP_ROOM="${PP_ROOM:-E2E4}"
PP_PORT="${PP_PORT:-8787}"
export PP_PLATFORMS PP_ROOM PP_PORT

has() { [[ " $PP_PLATFORMS " == *" $1 "* ]]; }

cd "$root"
dart pub get --directory core >/dev/null
dart pub get --directory server >/dev/null
(cd test && npm install --no-audit --no-fund >/dev/null)

if [[ "${PP_SKIP_BUILD:-0}" != "1" ]]; then
  pushd app >/dev/null
  flutter pub get >/dev/null
  has web && flutter build web --release
  has ios && flutter build ios --simulator --debug
  has macos && flutter build macos --debug
  # iOS/Android receive PP_* at launch time (simctl environment / intent extras).
  # Release APK: AOT code keeps software-emulated (TCG) Android devices usable.
  has android && flutter build apk --release
  popd >/dev/null
fi

# The reel is cut even for a failing run so the failure can be reviewed.
status=0
node "$here/e2e/run.mjs" || status=$?

if [[ "${PP_REVIEW_VIDEO:-1}" == "1" ]]; then
  if command -v ffmpeg >/dev/null; then
    "$here/review-video.sh" ${PP_EVIDENCE_DIR:+--e2e "$PP_EVIDENCE_DIR"} || echo "review-video: failed to build the edited reel" >&2
  else
    echo "review-video: ffmpeg not found, skipping the edited reel" >&2
  fi
fi
exit "$status"
