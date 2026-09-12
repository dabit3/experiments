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

Implementation and shell verification in progress. Visual review passes and final
computer-use evidence will be recorded here after running the actual simulator.
