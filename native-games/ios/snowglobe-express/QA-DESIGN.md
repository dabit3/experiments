# Snowglobe Express — V1 QA and design log

## Verified environment

- Native macOS arm64 VM (Darwin 25.5.0).
- Xcode 26.6, build 17F113.
- iOS 26.5 simulator runtime, build 23F73.
- Available iPhones include 17 Pro, 17 Pro Max, 17e, Air and 17.
- Simulator signing is disabled. No physical-device validation or App Store upload.

## Design baseline

Original procedural isometric miniature: curved glass, layered powder-blue roads,
porcelain cottages, snow-capped fir trees, amber windows and a cranberry parcel van.
The gold preview tile and diagonal direction controls describe the same grid.
Fuel is explicit before every move. A first-delivery tutorial teaches priority,
snow displacement and undo. Completion renders the actual illuminated game state
as a shareable postcard.

## Verification log

Initial Debug and Release simulator builds and strict `swift-format` lint passed.
XCTest passed on iPhone 17e: 9 tests, 0 failures. This includes three-star solutions
for all six routes, full-state undo, blocked/overflow moves, priority delivery,
last-fuel success, daily UTC stability, persistence and corrupt-save fallback.

### Pass 1 — composition and identity

The tester operated the native iPhone 17 Pro simulator through home, tutorial,
preview and the first move. Home and tutorial fit. Preview cost 2 fuel without
changing state, then Drive changed fuel from 15 to 13.

Observed: house 3's floating number overlapped the bakery doorway; the plain snow
depth number looked like another home and became hidden behind the building.
The playable portion of the globe was smaller than the available layout allowed.

Changes: enlarged the village's isometric spacing and gameplay globe; reduced
building/tree scale slightly; placed numbered home plaques beside their facades,
with all plaques drawn above the geometry. Snow depths now use compact dark pills
with a drawn snowflake, rendered over the artwork. Replaced the HUD's unexplained
priority dot with numbered home markers. Added interpolated van motion and amber
orbiting sparkles for the illuminated result.

### Pass 2 — readability and controls

The tester inspected the rebuilt game on iPhone 17 Pro. The revised board and
HUD were clearer. Preview east then north cost 1 then 2 without spending fuel.
Drive and Undo restored the initial snow, van and fuel; recorded intermediate
frames confirmed van interpolation. N,N,E,E,S,S won in 6 moves using 8 fuel,
with 3 stars and 1100 points. The result and actions fit.

Observed: the snow pill still collided with the bakery's delivered checkmark.
The van covered delivered windows when parked exactly on a house. Undo snapped
instead of using the same glide as Drive.

Changes: moved home badges to the left of their facade, away from the northbound
snow bank's pill; smoothly offset the van toward the curb as it approaches any
home, leaving its windows visible; applied the Drive animation to Undo.
Snow depth changes remain immediate logical turn updates.

### Pass 3 — small-screen review and sharing correction

On iPhone 17e, the tester verified home/tutorial fit, blocked moves, previews,
delivery Undo and the 1100-point success. Home badges and snow pills were distinct,
and all lit windows remained visible. The first share presentation opened an empty
sheet. The run was stopped and its artifacts retained as diagnostic evidence only.

The presentation used separate Boolean and optional image state. Changed it to
one identifiable postcard payload passed directly into `sheet(item:)`, so the
sheet content receives the image/text responsible for presenting it. A rendering
failure now reports an error while retaining the result.

The final retest will cover native sharing, failure/retry, persistence/settings,
daily play and large-screen fit, and produce a new annotated recording.
