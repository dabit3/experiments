# Afterglow

A personal photographic studio for iPhone. An editorial library, charcoal surfaces,
serif typography, precise tonal rulers, RGB scopes, and an uninterrupted photographic canvas.
Everything works offline. SwiftUI drives the interface; Core Image develops the actual
preview and exported pixels. Three original photographic studies make the first launch useful.

## Prerequisites and running

- Native macOS with Xcode 26.6 and an iOS Simulator runtime (verified with iOS 26.5).
- No package manager, third-party dependency, account, backend, or signing identity is required.
- The app targets iOS 18+, iPhone portrait. It is intentionally not an iPad app.

```sh
cd native-demos/ios/afterglow
bash Scripts/build.sh
xcrun simctl list devices available
# Boot an iPhone using its local identifier, then install and launch:
bash Scripts/run.sh <your-iphone-simulator-uuid>
# Or with an already booted iPhone:
bash Scripts/run.sh
```

Alternatively open `Afterglow.xcodeproj`, select the shared Afterglow scheme and an iPhone
Simulator, and Run. The checked-in project needs no generator. Local artifacts land in
`build/Build/Products/Debug-iphonesimulator/Afterglow.app`. This is a Simulator-only build;
it is not a signed iPhone or App Store release.

## Library and originals

- Open any photograph or continue developing the last selected image.
- **Import:** choose one or more originals from the native Photos picker or Files.
  JPEG, PNG, and HEIC are accepted, up to 50 megapixels and 80 MB per file.
  Files are copied into the local library with generated filenames; their sources stay untouched.
- **Starred:** favorites persist across relaunch. The collection shows real edited thumbnails.
- Photographic dimensions honor EXIF orientation. Imported titles come from filenames
  when importing from Files; Photos-picker imports receive a generic title.
- The bundled studies remain available alongside your imported photographs.

## The darkroom

- **Looks:** Original, Ember, Coastal, Silver, Dusk, with continuously adjustable intensity.
  The thumbnails are really rendered.
- **Light:** exposure (−2 to +2 EV), contrast (50–150), highlights and shadows (−100 to +100).
- **Color:** warmth (−100 to +100), saturation (0–200), vibrance (−100 to +100).
- **Detail:** luminance sharpening and vignette (0–100).
- Drag a precision ruler; one completed drag is one undo step.
  Release commits the last tracked value without recalculating the thumb position.
  Tap the numeric readout for exact entry, or the reset arrow for the selected adjustment.
- **RGB histogram:** computed from the rendered preview, with independently normalized
  RGB channels. Toggle it from the strip below the photograph.
- **Crop:** Full, 4:5, 1:1 or 16:9; rotate clockwise in 90° steps; zoom to 2.5×.
  Drag the image to reframe within the available crop margin.
- **Comparison:** hold “Hold original” to temporarily view original color with the current
  crop geometry. Split comparison shows before and after together; drag the divider.
- **Undo / Redo:** bounded history of 60 edits per image; branching clears redo.
- **Photograph actions:** copy/paste color and light between images while retaining the
  destination composition; inspect details; or reset all edits with confirmation.
  Reset itself can be undone.
- **Output studio:** JPEG with quality 50–100, or lossless PNG. Choose full resolution,
  2048 px or 1080 px longest edge; smaller originals are never enlarged.
  Export writes a real file and displays its preview, dimensions and byte size.
  Use “Share or save to Files” to open the native share sheet.

Editable settings, imports, favorites, active photo and undo/redo are atomically saved.
V1 projects migrate on read with neutral defaults for new controls, preserving their history.
Original images never change. Per-photo edits survive switching photos and relaunch.
Copied edits stay available for the current app session.

## Storage and exports

Within the app's Documents directory:

```
Afterglow/project.json
Afterglow/Originals/<unique-id>.<jpg|png|heic>
Afterglow/Exports/Afterglow-<photo>-<unique-id>.<jpg|png>
```

Files are exposed via iOS Files / Finder file sharing. On Simulator:

```sh
CONTAINER="$(xcrun simctl get_app_container booted ai.devin.afterglow data)"
ls "$CONTAINER/Documents/Afterglow/Exports"
```

A failed import/save/export surfaces a readable error. Unreadable or unsupported project data
is preserved and never overwritten. Bundled studies can still be explored and exported,
but that session cannot save or import until the library file is recovered externally.

## Sample art

`Assets/dunes.jpg`, `coast.jpg`, and `bloom.jpg` are original AI-generated photographic
studies created for this demo with OpenAI gpt-image-2 on September 11, 2026. They depict
imagined desert/coastal/studio scenes, not documentary photographs. No downloaded
third-party photography, trademarks, or recognizable people are included.
Source size: 1024 × 1536 per image. The original images ship locally and remain editable.

## Verification

```sh
bash Scripts/check.sh
bash Scripts/build.sh
# Apply the native formatter if editing Swift:
xcrun swift-format format --in-place --recursive Afterglow AfterglowCore Tests Package.swift
```

`swift test` runs the same Foundation/Core Image editing engine on native macOS. Tests
cover history branching/reset, bounds and nonfinite inputs, crop geometry/pan/zoom,
project serialization and V1 migration, imported-library/favorite persistence, EXIF orientation,
invalid import rejection, real pixel changes for all looks and advanced controls, histogram
normalization/clipping, rotation, JPEG round-trip dimensions and monochrome pixels,
lossless PNG export and output resizing without upscaling. `swift-format --strict` is the
lint check. The iOS build separately typechecks the complete SwiftUI app.

Native UI acceptance: inspect library and all studies; star and filter; import a local photo;
apply a look and intensity, adjust exposure in both directions, enter a numeric value,
adjust highlights/shadows/color/detail, crop/reframe/rotate, hold and split original comparison,
undo/redo, copy/paste color between photographs, reset/cancel/recover; configure and export
JPEG and PNG, share through Files and verify decoded pixels/dimensions; terminate/relaunch
and confirm the imported original, favorites, edits and selection persist.

## Modeling limits

- Local creative studio, not an Adobe replacement: no RAW development, masks, layers,
  custom curves, lens profiles, camera capture, cloud sync, printing or batch export.
- Library import supports JPEG/PNG/HEIC still images. No video, GIF animation or Live Photo
  motion is retained. Library deletion, renaming and album management are not provided.
- Film looks are explicit exposure/temperature/contrast/saturation recipes, not measured
  physical film-stock emulations. Temperature is a relative Core Image white-balance shift.
- Crop ratios use integer pixel bounds (sub-pixel aspect error is possible); reframe uses
  normalized available margins. Rotations are clockwise quarter turns.
- The interactive preview is limited to a 1400-pixel longest edge. Sharpening is applied at
  the render resolution, so fine-detail appearance can differ between preview and export.
  Exports use the chosen size after cropping and rotation, without synthetic upscaling.
- Export is flattened 8-bit sRGB and omits capture metadata. Wide-gamut/HDR originals are
  converted to this working output; this is not a 16-bit color-managed archival workflow.
- Histogram sampling fits the preview within 160 pixels and uses 64 bins per channel.
  The scope is a tonal guide, not a calibrated raw-data exposure meter.
- The Photos picker grants access only to chosen files; no whole-library permission required.
- Portrait-only, with scrolling on short displays or larger text sizes; iPhone is the
  supported platform. VoiceOver labels and adjustable precision rulers are provided.
