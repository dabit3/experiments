# Arcade redesign audit

Source commit: `703c987a67be76cd88e14fafddd00318fddb096d`

Revision: `sha256:c4ab07ded4212875064fd8201f8a3fbd9584f47279a1d315c029b2c61e654bbc`

## source

The reference boundary is unchanged: public chess rules, SAN/PGN conventions and
the user's enumerated online-chess requirements. The commercial original was
never run or purchased. Its exact screens and private behavior remain
inaccessible; no comparison claims to reproduce them. The user explicitly
requested an original arcade redesign, superseding the earlier visual direction.

Reviewed the entry point, controller, lobby/game/results/review widgets, shared
rules package, server, protocol, README and current test harness against the
26 existing inventory records. Source, tests, lockfiles, assets and native project
configuration are included in `fingerprint-list.txt`. Evidence is excluded by
the skill's existing fingerprint contract.

## navigation

Current manual invite flow `JULPAM` proceeds from lobby to game, checkmate,
clipboard export, PGN import and keyboard history review. A separate current bot
game proceeds to resignation. Network room `U8LZ5W` traverses lobby, waiting,
gameplay, history, result, rematch and imported review. Match settings remain
available under the lobby expander. There are no billing, administrator or
account-recovery routes in this product.

## roles

The current network run seats native macOS as White, web as Black and iOS as
spectator. Rematch swaps the player colors. Core/server tests cover illegal,
wrong-turn and spectator move rejection, quick pairing, bot behavior and
reconnection. These are anonymous local client identities, not authenticated
user accounts. Authorization within a room must not be described as a
production account-authentication system.

## states

The deterministic match has 58 passing assertions, including final shared state,
spectator reconnect, history, PGN and rematch. Current screenshots cover waiting,
live turn indication, checkmate, rematch and both themes. Manual current captures
cover checkmate and resignation at 375×812, both dark and light, and imported
initial/final positions.

Prior manual promotion-picker, detailed move-input and offer-dialog exercises
are supplemental evidence from earlier revisions; they are not relabeled as
current screenshots. Current rules, controller/board source inspection and
39 unit/widget/integration tests provide regression coverage for their unchanged
logic. No static screen substitutes for server state.

## responsive

Inspected current 1440×900 and 375×812 web captures, 1000-pixel web/native windows,
and the iPhone Simulator captures. The result card stays inside the board in both
phone themes. All result actions are readable. The iOS active scoreboard fits
during gameplay and rematch after increasing its compact allocation to 60.
Secondary player metadata may ellipsize in short desktop demonstration windows;
the player name, clock, move list and primary actions remain visible.

Four native-versus-web comparisons pass with zero differing normalized blocks:
lobby/review on iOS at 402×812, and lobby/review on macOS at 1000×488.
The unchanged normalization downsamples to logical pixels, then compares 20×20
blocks with 0.25 coverage and 24/255 color bounds. It does not establish literal
pixel equality, fine-grained renderer identity or parity with a commercial game.
Raw pairs, metrics and diff images are retained under `network/parity/`.

## data

Every current network client ends at:

`1n1Rkb1r/p4ppp/4q3/4p1B1/4P3/8/PPP2PPP/2K5 b k - 1 17`

They share the 33-entry SAN list ending `Rd8#`, score `1-0`, checkmate result and
frozen clocks `whiteMs=212000`, `blackMs=210000`. PGN exports agree and import
recreates the position. The authoritative server uses in-memory rooms and
reconnect state; there is no claim of durable match persistence after a server
restart. PGN is the explicit portable game export.

## assets

The current artwork is an original generated arena illustration plus custom
vector crown, chess pieces, app icons and generated sounds. Bungee, Manrope and
IBM Plex Mono are bundled with their license notices. No commercial-game
artwork or branding was copied. The clients load shared local assets.
Audible iOS feedback remains unverified: Simulator CoreAudio logs report no
default output device, error -66680 and volume-scalar error 560947818. The sound
assets and failure handling are present, but that does not prove audible output.
The redesign's hierarchy uses cobalt, navy and yellow, while the board stays
unobstructed by decorative artwork.

## accessibility

Reviewed button semantics, tooltips, focus handling, game keyboard shortcuts,
pointer/touch handling and the current keyboard PGN review. `contrast.json`
computes 37 token combinations from source: body/secondary/faint text on four
surfaces in both themes, live badges, board coordinates and primary buttons.
All meet 4.5:1, with a minimum of 4.542:1. This is a bounded static color check,
not a complete accessibility certification. Disabled states, arbitrary text
scaling, every translucent combination, screen-reader move announcements and
reduced-motion behavior were not independently certified.

## reliability

The clean detached checkout at `703c987` installs dependencies, analyzes and tests
core/server/app, checks Dart formatting, ShellCheck, Node syntax, Ruff and Python
compilation, and builds web release, macOS release, iOS Simulator and Android APK.
See `builds/clean-checkout.txt`. All 39 tests and all four builds pass.

Runtime UI verification uses web release and instrumented native debug builds;
native release builds are compiled separately. Do not describe the native
instrumented run as release-runtime verification. Build logs retain Flutter's
unused Cupertino icon-font warning and Xcode's script-phase dependency warning.
The inspected native and server logs show no application failure; iOS has the
CoreAudio limitation above. The manual browser console has only three
script-injection debug messages and no page errors. The network harness did not
persist its browser console, so it cannot support a separate clean-console claim.

The earlier pass3 unrecorded startup failed before gameplay with a local web
navigation timeout. The unchanged retry passed; a macOS Python local-network
permission prompt was subsequently allowed. Earlier failed evidence is retained.
The final pass4 run succeeds without changing thresholds or assertions.

The Android APK builds, but `android-host.txt` still reports `kern.hv_support: 0`.
The previous emulator-launch failures remain the external blocker. No Android
runtime screenshot or four-device success is claimed.

The built-in recording editor compressed 83.267 seconds to 11.792 seconds.
The delivered 80-second, 15fps fallback preserves real-time playback and adds
explicitly postprocessed captions. It starts with the three windows already
separated and ends before parity navigation/resizing. The late desktop screenshot
is named `fullscreen-rematch.png`; `fullscreen-checkmate.png` is a verified frame
extracted at raw 60 seconds. These recording-tool corrections do not change the
application or harness source.

## rebrand

Current window titles, app metadata, crown mark, marquee and result presentation
identify Gambit Court. Typography is shared across targets; game result semantics
are role-aware (victory, defeat, spectator winner). Source names in public rules
and font-license attribution are retained. Only `gambit-court/` is changed in the
repository.

## security

The clean current server answers `/health` and returns 404 for `/control/state`
without `--control`; see `security-check.txt`. The CLI binds to `0.0.0.0` by
default, while this probe explicitly uses loopback. The test bridge is opt-in,
not an authenticated public API.

Current source-pattern and tracked secret-filename checks found no matches.
The Node lockfile audit reports zero vulnerabilities in the harness dependency;
this is not a blanket certification of every transitive Dart/native dependency.
Server tests validate role/move rejection. The deterministic fixtures use local
synthetic identities and local clients, with no production mutations.
