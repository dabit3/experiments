# Full-game native-control evidence harness

Native UI flow recorded against app revision `12c7504` on macOS 26 / Xcode 26.6.
The reusable harness includes subsequent typed-input, configuration and lint
cleanup; retained recordings identify their own source provenance. No accounts
or secrets are needed.

This is **one scripted operator alternating two native simulator windows**, not
two human players and not simultaneous multitouch. The in-app autonomous drivers
stay disabled. The product's `TOUCH INPUT / HUMAN PLAYER` label means the native
input path, not that humans performed this run.

`native-touch.swift` uses public macOS Accessibility to raise the selected
Simulator window and CGEvent mouse-down/up to operate its actual visible controls.
`play.py` uses **GET-only** `/rooms` observations to gate phases, observe distance,
and recover a checkpoint. It never sends gameplay packets or changes server state.
Ren's strategy is heavy-led; Aya's is light/heavy-led. Both perform projectile
specials, timed defenses, jumps, movement and Shift when available. Results come
from real hits and normal server combat rules.

## Prerequisites and layout

- Build current app sources (Xcode/XcodeGen required):
  `xcodegen generate`, then
  `xcodebuild -project HollowAfterdark.xcodeproj -scheme HollowAfterdark -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath build CODE_SIGNING_ALLOWED=NO build`.
  This recorded run installed the existing verified simulator build.
- Server dependencies: `npm --prefix Server ci` if not already present.
- Python3 standard library, Swift/Clang, ripgrep, FFmpeg with AVFoundation, macOS
  Accessibility and Screen Recording permission for the calling process.
- Approved BlackHole 2ch setup as documented in the root README. Verify
  `system_profiler SPAudioDataType` shows default input/output/system output,
  stereo 48kHz **before booting simulators**. Restart those booted without output.
- Display is **1600×1200**. Simulator windows are **910×518** in landscape:
  iPhone 17 at `(300,40)` and iPhone 17 Pro at `(300,590)`.
  Both full displays must remain unobscured. Do not interact with the host pointer
  while the input harness runs.
- These coordinates/window titles are intentionally explicit, not universal.
  If your runtime/device/scale differs, calibrate `BUTTONS`, scene transform,
  window titles, and export crops against screenshots **before** a fresh run.
  Rotate Simulator via its native Device menu/Cmd-left as needed.

From `hollow-afterdark/`, choose a NEW evidence folder and 4–8 character room:

```sh
export EVIDENCE="$PWD/.devin/clone-this/hollow-afterdark/evidence/tests-native-controls-NEW"
export ROOM=HCNEW1
mkdir -p "$EVIDENCE"
# Discover IDs on THIS host; never copy simulator UUIDs from another session.
xcrun simctl list devices available
export DEVICE_A='<your iPhone 17 UUID>'
export DEVICE_B='<your iPhone 17 Pro UUID>'
test "$DEVICE_A" != "$DEVICE_B"
export APP="$PWD/build/Build/Products/Debug-iphonesimulator/HollowAfterdark.app"

# Start a fresh real server only if this local test port is not already in use.
PORT=8788 HOST=127.0.0.1 node Server/server.mjs > "$EVIDENCE/server.jsonl" 2>&1 &
SERVER_PID=$!
# Boot only these devices if shutdown; an already-booted warning is harmless.
xcrun simctl boot "$DEVICE_A"
xcrun simctl boot "$DEVICE_B"
xcrun simctl bootstatus "$DEVICE_A" -b
xcrun simctl bootstatus "$DEVICE_B" -b
xcrun simctl install "$DEVICE_A" "$APP"
xcrun simctl install "$DEVICE_B" "$APP"
# Terminate existing app instances first if present, to ensure fresh arguments.
xcrun simctl terminate "$DEVICE_A" ai.afterdark.hollow.duel
xcrun simctl terminate "$DEVICE_B" ai.afterdark.hollow.duel
xcrun simctl launch "$DEVICE_A" ai.afterdark.hollow.duel \
  --server ws://127.0.0.1:8788 --room "$ROOM" --name Ren
xcrun simctl launch "$DEVICE_B" ai.afterdark.hollow.duel \
  --server ws://127.0.0.1:8788 --room "$ROOM" --name Aya
open -a Simulator
```

**Never add `--driver` or `--autojoin`.** Confirm new unjoined lobbies.
After rotating landscape, discover window titles and select the screen device.
The helpers deliberately require these host-specific environment variables:

```sh
osascript -e 'tell application "System Events" to tell process "Simulator" to get name of every window'
# Set exact titles from the preceding output (examples, not fixed runtime requirements).
export WINDOW_A='iPhone 17 – iOS 26.5'
export WINDOW_B='iPhone 17 Pro – iOS 26.5'
ffmpeg -hide_banner -f avfoundation -list_devices true -i ""
# Choose the index labelled "Capture screen 0", NOT a camera.
export SCREEN_DEVICE='<screen device index from the list>'
osascript \
  -e 'tell application "System Events" to tell process "Simulator"' \
  -e "set position of window \"$WINDOW_A\" to {300,40}" \
  -e "set position of window \"$WINDOW_B\" to {300,590}" \
  -e 'get {name, position, size} of every window' -e 'end tell'
clang Tests/NativeUI/queue.c -framework AudioToolbox -framework CoreAudio \
  -framework CoreFoundation -o "$EVIDENCE/queue"
swiftc Tests/NativeUI/native-touch.swift -o "$EVIDENCE/native-touch"
```

Recorder metadata reads the actual checkout revision, helper source hashes and
selected simulator IDs.
All helper sources live in this directory; no prior/ignored evidence, binaries,
session UUIDs or secret files are required. Fresh evidence directories are created
by the commands above. Calibrated coordinates still require the documented layout.

## Continuous capture and native-control execution

```sh
set -e
python3 Tests/NativeUI/capture.py > "$EVIDENCE/capture-stdout.jsonl" 2>&1 &
CAPTURE_PID=$!
# Bounded readiness, before any lobby input.
python3 - <<'PY'
import os,pathlib,time
p=pathlib.Path(os.environ["EVIDENCE"])
files=[p/n for n in ("raw-video.mkv","raw-audio.s16le","raw-audio.jsonl")]
deadline=time.monotonic()+30
while time.monotonic()<deadline:
    if all(f.exists() and f.stat().st_size>0 for f in files):break
    time.sleep(.2)
assert all(f.exists() and f.stat().st_size>0 for f in files),"Capture not ready"
PY
ls -lh "$EVIDENCE"/raw*
python3 Tests/NativeUI/play.py join
# Inspect driver-disabled-lobby.png: both TOUCH INPUT labels, same room, two peers.
python3 Tests/NativeUI/play.py ready
python3 Tests/NativeUI/play.py play > "$EVIDENCE/play-stdout.jsonl" 2>&1 &
PLAY_PID=$!
# Exercise actual checkpoint resumption after the first saved round opening.
python3 - <<'PY'
import os,pathlib,time
p=pathlib.Path(os.environ["EVIDENCE"]);deadline=time.monotonic()+30
while not (p/"play-checkpoint.json").exists() and time.monotonic()<deadline:
    time.sleep(.1)
assert (p/"play-checkpoint.json").exists(),"No opening checkpoint"
(p/"PAUSE").touch()
PY
wait "$PLAY_PID"
rm "$EVIDENCE/PAUSE"
python3 Tests/NativeUI/play.py play >> "$EVIDENCE/play-stdout.jsonl" 2>&1
# play runs two full matches and native REMATCH consents after the first result.
# It returns at the second genuine result, preserving screenshots.
python3 Tests/NativeUI/play.py audio > "$EVIDENCE/audio-ui-stdout.jsonl" 2>&1
wait "$CAPTURE_PID"
ps ax -o pid,command | rg '[H]ollowAfterdark.app/HollowAfterdark' > "$EVIDENCE/app-process-arguments.txt"
python3 Tests/NativeUI/audit.py > "$EVIDENCE/audit-stdout.json"
python3 Tests/NativeUI/export.py > "$EVIDENCE/export-stdout.log" 2>&1
python3 Tests/NativeUI/verify-delivery.py > "$EVIDENCE/delivery-audit-stdout.json"
```

If a step fails, do not blindly continue the sequence. Inspect the live UI,
checkpoint and observer; report product defects without editing production source.
The captures are bounded to 595 seconds; play is bounded to 480 seconds.
Keep the entire full-game output, not merely a join excerpt.

## Pause/resume and graceful stop

- `touch "$EVIDENCE/PAUSE"` pauses inputs at the next safe action boundary.
  Every hold is bounded to at most five seconds and released; the original screen/audio capture and
  authoritative game timer continue. This is **not** a server pause.
- Remove `PAUSE`, rerun `play.py play`. It preserves completed round openings and
  turn count from atomically written `play-checkpoint.json`, checks connected
  named peers, and resumes the actual observed match/round.
- Append resumed stdout with `>>` rather than overwriting. `capture-events.jsonl`
  always appends native request/completion timestamps and assertions.
- `touch "$EVIDENCE/STOP"` gracefully closes video and AudioQueue; do not SIGKILL.
  To stop only input, use `PAUSE` and let the bounded native hold release.
- A capture interruption requires a **new directory/segment**. The recorder
  refuses to overwrite existing raw video. Never conceal a break with splicing.
- If the result screen is already match2, `play` returns without triggering
  another rematch. Audio audit starts from both result screens / both AUDIO ON.

## Evidence and limitations

Primary: `PRIMARY-full-game-native-controls.mp4`, both complete displays side by
side with actual action/phase timestamps rendered as captions. Input actions are
never replaced with API mutations. The three source modules are deliberately
separate: native pointer, read-only observation, native media recording.

The available recording tool cannot import/register custom synchronized media;
its annotation API rejects this stream as "no active recording". Avoid starting
a competing second recorder. Present the **full-game MP4 as primary**, not the
older join-regression native viewer. Captions/assertions are generated directly
from `capture-events.jsonl` instead.

`queue.c` retains original native sample/host times. Audit exact frame/byte counts,
sample and storage continuity, ON/OFF/ON raw PCM and video frame intervals.
Only excess PCM head/tail is trimmed; no padding, resampling or soundtrack.
Export runs complete FFmpeg decodes of raw, master and delivery. Inspect actual
moving playback and full-screen screenshots before sharing. Disclose video gaps
even if audio is perfectly contiguous.

This focused run does not reverify physical multitouch, high latency, reconnect,
throw/escape, enabled EX/resource rejection, or isolated sound-effect quality.
Do not overwrite the older automated-driver, silent, failed or qualified evidence.
The strict stable-label/PCM check can fail even when clicks, audio suppression and
sample continuity pass. Preserve its measured failure; inspect original frames
and native frame intervals, and do not silently relax its 250ms threshold.
Audit commands retain JSON evidence and exit nonzero when an assertion fails.

## Harness checks

From the game directory, install the pinned Python linter in an isolated local
environment (Python 3.9 or newer):

```sh
python3 -m venv .devin/native-ui-lint
.devin/native-ui-lint/bin/python -m pip install ruff==0.12.12
.devin/native-ui-lint/bin/ruff check --select E4,E7,E9,F,I Tests/NativeUI
.devin/native-ui-lint/bin/ruff format --check Tests/NativeUI
xcrun swift-format lint --strict --recursive Tests/NativeUI
swiftc -typecheck Tests/NativeUI/native-touch.swift
swiftc -typecheck Tests/NativeUI/banners.swift
clang -Wall -Wextra -Werror -fsyntax-only Tests/NativeUI/queue.c
```
