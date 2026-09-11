#!/usr/bin/env bash
# Cross-platform multiplayer end-to-end test for Nitro Tots.
#
# Starts the authoritative server with a fixed seed, launches one client per
# platform (web via Playwright, iOS Simulator via simctl, Android emulator via
# adb, native macOS app), has them all join the same room, lets the scripted
# Autopilot drive a full Grand Prix, then asserts that every client reported
# the same final standings and result hash as the server. Screenshots for each
# room phase per platform plus a screen recording of the four-way match are
# written to the evidence directory.
#
# Usage:  test/multiplayer-e2e.sh
# Env:    NT_PLATFORMS="web ios android macos"   platforms to launch
#         NT_ROOM=E2E  NT_SEED=4242  NT_PORT=8787  NT_WEB_PORT=8080
#         NT_LAPS=1    NT_CUP=sugar  (Grand Prix cup; 4 races)
#         NT_BUILD=1   set to 0 to reuse existing builds
#         NT_RECORD=1  set to 0 to skip the screen recording
#         NT_OUT=<dir> evidence directory (default: clone-this run evidence)
#         NT_TIMEOUT=900 seconds to wait for the match to finish
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
APP="$ROOT/app"
SERVER_PKG="$ROOT/packages/nitro_server"
TEST_DIR="$ROOT/test"

PLATFORMS=${NT_PLATFORMS:-"web ios android macos"}
ROOM=${NT_ROOM:-E2E}
SEED=${NT_SEED:-4242}
PORT=${NT_PORT:-8787}
WEB_PORT=${NT_WEB_PORT:-8080}
LAPS=${NT_LAPS:-1}
CUP=${NT_CUP:-sugar}
BUILD=${NT_BUILD:-1}
RECORD=${NT_RECORD:-1}
TIMEOUT=${NT_TIMEOUT:-900}
STAMP=$(date +%Y%m%d-%H%M%S)
OUT=${NT_OUT:-"$ROOT/.devin/clone-this/nitro-tots/evidence/multiplayer/$STAMP"}
IOS_BUNDLE=dev.nitrotots.nitroTots
ANDROID_PKG=dev.nitrotots.nitro_tots
SERVER_HTTP="http://127.0.0.1:$PORT"
SERVER_WS="ws://127.0.0.1:$PORT/ws"
APP_URL="http://127.0.0.1:$WEB_PORT/"
DEFINES=(--dart-define=NT_TEST=true --dart-define=NT_ROOM="$ROOM" --dart-define=NT_LAPS="$LAPS" --dart-define=NT_CUP="$CUP")

mkdir -p "$OUT/screenshots" "$OUT/logs"
PIDS=()
log() { printf '[e2e %s] %s\n' "$(date +%H:%M:%S)" "$*" | tee -a "$OUT/logs/e2e.log"; }
have() { [[ " $PLATFORMS " == *" $1 "* ]]; }
count_players() { echo "$PLATFORMS" | wc -w | tr -d ' '; }

cleanup() {
  log "cleaning up"
  if [[ -n "${REC_PID:-}" ]]; then
    kill -TERM "$REC_PID" 2>/dev/null || true
    wait "$REC_PID" 2>/dev/null || true
  fi
  for p in "${PIDS[@]:-}"; do [[ -n "$p" ]] && kill "$p" 2>/dev/null || true; done
  have ios && xcrun simctl terminate booted "$IOS_BUNDLE" >/dev/null 2>&1 || true
  have android && adb shell am force-stop "$ANDROID_PKG" >/dev/null 2>&1 || true
  pkill -f "Nitro Tots.app/Contents/MacOS/Nitro Tots" 2>/dev/null || true
}
trap cleanup EXIT

# ---------------------------------------------------------------- preflight
log "platforms: $PLATFORMS  room: $ROOM  seed: $SEED  cup: $CUP  laps: $LAPS"
log "evidence: $OUT"
if [[ "$RECORD" == 1 ]] && ! { command -v ffmpeg >/dev/null && command -v ffprobe >/dev/null; }; then
  log "FAIL: recording requires ffmpeg and ffprobe (brew install ffmpeg), or set NT_RECORD=0."
  exit 3
fi
if have android; then
  if ! adb devices 2>/dev/null | awk 'NR>1 && $2=="device"' | grep -q .; then
    log "FAIL: 'android' requested but no emulator/device is attached (adb devices). Boot an AVD or set NT_PLATFORMS without android."
    exit 3
  fi
fi
if have ios; then
  if ! xcrun simctl list devices booted | grep -q Booted; then
    log "FAIL: 'ios' requested but no iOS Simulator is booted (xcrun simctl boot <device>)."
    exit 3
  fi
fi
if lsof -iTCP:"$PORT" -sTCP:LISTEN >/dev/null 2>&1; then
  log "FAIL: port $PORT already in use; stop the other server or set NT_PORT."
  exit 3
fi
[[ -d "$TEST_DIR/node_modules/playwright" ]] || (cd "$TEST_DIR" && npm install --no-audit --no-fund >"$OUT/logs/npm.log" 2>&1)

# ------------------------------------------------------------------- builds
if [[ "$BUILD" == 1 ]]; then
  (cd "$APP" && flutter pub get >"$OUT/logs/pub.log" 2>&1)
  if have web; then log "building web"; (cd "$APP" && flutter build web --release >"$OUT/logs/build_web.log" 2>&1); fi
  if have ios; then log "building ios (simulator)"; (cd "$APP" && flutter build ios --simulator --debug >"$OUT/logs/build_ios.log" 2>&1); fi
  if have macos; then log "building macos"; (cd "$APP" && flutter build macos --release >"$OUT/logs/build_macos.log" 2>&1); fi
  if have android; then log "building android"; (cd "$APP" && flutter build apk --release "${DEFINES[@]}" >"$OUT/logs/build_android.log" 2>&1); fi
fi
MAC_BIN="$APP/build/macos/Build/Products/Release/Nitro Tots.app/Contents/MacOS/Nitro Tots"
IOS_APP="$APP/build/ios/iphonesimulator/Runner.app"
APK="$APP/build/app/outputs/flutter-apk/app-release.apk"

# ------------------------------------------------------------------- server
log "starting server on :$PORT (seed $SEED)"
(cd "$SERVER_PKG" && dart run bin/nitro_server.dart --port "$PORT" --seed "$SEED" -v >"$OUT/logs/server.log" 2>&1) &
PIDS+=($!)
for _ in $(seq 1 60); do curl -sf "$SERVER_HTTP/health" >/dev/null && break; sleep 1; done
curl -sf "$SERVER_HTTP/health" >"$OUT/logs/health.json" || { log "FAIL: server did not start"; exit 4; }
log "server healthy: $(cat "$OUT/logs/health.json")"

if have web; then
  (cd "$APP/build/web" && python3 -m http.server "$WEB_PORT" --bind 127.0.0.1 >"$OUT/logs/web_server.log" 2>&1) &
  PIDS+=($!)
  for _ in $(seq 1 30); do curl -sf "$APP_URL" >/dev/null && break; sleep 1; done
fi

# ---------------------------------------------------------------- recording
# Window layout on a 1600x1200 desktop: web top-left, macOS top-right,
# iOS (landscape) bottom-left, Android bottom-right.
if [[ "$RECORD" == 1 ]]; then
  ffmpeg -y -hide_banner -loglevel warning \
    -f avfoundation -framerate 30 -pixel_format bgr0 -capture_cursor 1 \
    -i 'Capture screen 0:none' -t "$TIMEOUT" -vf 'scale=1280:-2' \
    -r 30 -c:v libx264 -preset veryfast -crf 28 -pix_fmt yuv420p -an \
    "$OUT/four-way-match.mp4" >"$OUT/logs/record.log" 2>&1 &
  REC_PID=$!
  log "screen recording started (pid $REC_PID)"
fi

# ------------------------------------------------------------------ clients
PLAYERS=$(count_players)
COMMON_ENV=(NT_TEST=1 NT_ROOM="$ROOM" NT_PLAYERS="$PLAYERS" NT_LAPS="$LAPS" NT_CUP="$CUP" NT_PORT="$PORT")

if have macos; then
  log "launching macOS app"
  env "${COMMON_ENV[@]}" "$MAC_BIN" >"$OUT/logs/macos.log" 2>&1 &
  PIDS+=($!)
  for _ in $(seq 1 30); do
    osascript -e 'tell application "System Events" to set position of window 1 of process "Nitro Tots" to {800, 30}' \
      -e 'tell application "System Events" to set size of window 1 of process "Nitro Tots" to {800, 560}' >/dev/null 2>&1 && break
    sleep 1
  done
fi

if have ios; then
  log "launching iOS simulator app"
  xcrun simctl terminate booted "$IOS_BUNDLE" >/dev/null 2>&1 || true
  xcrun simctl install booted "$IOS_APP"
  SIM_ENV=()
  for kv in "${COMMON_ENV[@]}"; do SIM_ENV+=("SIMCTL_CHILD_$kv"); done
  env "${SIM_ENV[@]}" xcrun simctl launch booted "$IOS_BUNDLE" >>"$OUT/logs/ios.log" 2>&1
  osascript -e 'tell application "System Events" to tell process "Simulator"
      set frontmost to true
      set {w, h} to size of window 1
      if w < h then click menu item "Rotate Left" of menu "Device" of menu bar 1
    end tell' >/dev/null 2>&1 || true
  sleep 1
  osascript -e 'tell application "System Events" to set position of window 1 of process "Simulator" to {0, 600}' >/dev/null 2>&1 || true
  open -g -a Simulator >/dev/null 2>&1 || true
fi

if have android; then
  log "launching Android app"
  adb install -r "$APK" >>"$OUT/logs/android.log" 2>&1
  adb shell am start -n "$ANDROID_PKG/.MainActivity" >>"$OUT/logs/android.log" 2>&1
fi

if have web; then
  log "launching web client (Playwright)"
  (cd "$TEST_DIR" && node web_client.mjs "$APP_URL?test=1&room=$ROOM&players=$PLAYERS&laps=$LAPS&cup=$CUP&port=$PORT" \
      "$SERVER_HTTP" "$ROOM" "$OUT/screenshots" "0,30,800,560" >"$OUT/logs/web.log" 2>&1) &
  PIDS+=($!)
fi

# macOS drops notification banners (e.g. for a fresh Chromium bundle) on top of
# the macOS client window; dismiss them so captures and the recording stay clean.
dismiss_notifications() {
  osascript "$TEST_DIR/dismiss_notifications.applescript" >/dev/null 2>&1 || true
}

# Stray windows from earlier runs (a leftover Playwright Chromium, a Finder
# window) can cover the macOS client; keep it on top so region captures and
# the recording show the app rather than whatever landed over it.
raise_macos() {
  have macos || return 0
  osascript -e 'tell application "System Events" to tell process "Nitro Tots"
      set frontmost to true
      perform action "AXRaise" of window 1
    end tell' >/dev/null 2>&1 || true
}

if have macos && pgrep -f 'ms-playwright/.*Chromium\.app/Contents/MacOS/Chromium' >/dev/null 2>&1; then
  log "warning: a Playwright Chromium from another run is already open; raising the macOS client above it"
fi
raise_macos

# ------------------------------------------------------- native screenshots
shot_native() { # <phase>
  local phase=$1
  dismiss_notifications
  if have ios; then
    local shot="$OUT/screenshots/ios_$phase.png"
    xcrun simctl io booted screenshot "$shot" >/dev/null 2>&1 || true
    # simctl captures the panel's native portrait framebuffer; turn it upright.
    if [[ -f "$shot" ]] && [[ "$(sips -g pixelWidth "$shot" | awk '/pixelWidth/{print $2}')" -lt "$(sips -g pixelHeight "$shot" | awk '/pixelHeight/{print $2}')" ]]; then
      sips -r 270 "$shot" >/dev/null 2>&1 || true
    fi
  fi
  if have android; then adb exec-out screencap -p >"$OUT/screenshots/android_$phase.png" 2>/dev/null || true; fi
  if have macos; then
    raise_macos
    local rect
    rect=$(osascript -e 'tell application "System Events" to tell process "Nitro Tots"
        set {x, y} to position of window 1
        set {w, h} to size of window 1
        return (x as text) & "," & (y as text) & "," & (w as text) & "," & (h as text)
      end tell' 2>/dev/null || true)
    [[ -n "$rect" ]] && screencapture -x -R "$rect" "$OUT/screenshots/macos_$phase.png" >/dev/null 2>&1 || true
  fi
  screencapture -x "$OUT/screenshots/desktop_$phase.png" >/dev/null 2>&1 || true
}

log "waiting for room $ROOM to finish (timeout ${TIMEOUT}s)"
last=""
mid_taken=0
racing_since=0
deadline=$((SECONDS + TIMEOUT))
while (( SECONDS < deadline )); do
  status=$(curl -sf "$SERVER_HTTP/rooms/$ROOM" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("status",""))' 2>/dev/null || true)
  if [[ -n "$status" && "$status" != "$last" ]]; then
    last=$status
    log "room status: $status"
    if [[ "$status" == racing ]]; then
      racing_since=$SECONDS; sleep 9
    elif [[ "$status" == lobby ]]; then
      # Capture the lobby once every seat is filled (clients delay "ready" so it stays visible).
      for _ in $(seq 1 40); do
        n=$(curl -sf "$SERVER_HTTP/rooms/$ROOM" | python3 -c 'import json,sys; print(len(json.load(sys.stdin).get("players",[])))' 2>/dev/null || echo 0)
        [[ "$n" -ge "$PLAYERS" ]] && break
        sleep 0.5
      done
      sleep 1.5
    else
      sleep 2.5
    fi
    shot_native "$status"
    [[ "$status" == matchOver ]] && break
  elif [[ "$status" == racing && $mid_taken == 0 && $((SECONDS - racing_since)) -ge 30 ]]; then
    mid_taken=1
    shot_native racing_mid
  fi
  sleep 1
done
sleep 4
curl -sf "$SERVER_HTTP/rooms" >"$OUT/logs/rooms_final.json" || true

# ---------------------------------------------------------------- verdict
set +e
python3 "$TEST_DIR/verify_room.py" "$SERVER_HTTP" "$ROOM" "$OUT" $PLATFORMS | tee -a "$OUT/logs/e2e.log"
rc=${PIPESTATUS[0]}
set -e
if [[ -n "${REC_PID:-}" ]]; then
  kill -TERM "$REC_PID" 2>/dev/null || true
  wait "$REC_PID" 2>/dev/null || true
  REC_PID=""
  if ! ffprobe -v error -show_entries format=duration -of csv=p=0 \
    "$OUT/four-way-match.mp4" >"$OUT/logs/recording-duration.txt"; then
    log "FAIL: screen recording is missing or invalid; see logs/record.log."
    rc=1
  fi
fi
if [[ $rc -eq 0 ]]; then log "PASS: all clients ($PLATFORMS) agree on the final standings and hash"; else log "FAIL: see $OUT/result.md"; fi
exit $rc
