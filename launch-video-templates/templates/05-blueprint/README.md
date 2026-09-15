# 05 — Blueprint

A 44-second technical drawing for Devin on macOS and iOS. Midnight paper,
cyan construction lines, exploded screenshot planes, sparse leaders, dimension
ticks, and a persistent lower-right drawing block. The native iPhone is the
foreground layer; the Devin session is its backing plane. The review beat
resolves into a flat, assembled frame containing a real recording.

## Editing and rendering

Run from `launch-video-templates`:

```sh
npm ci
npm run lint
npm run typecheck
npm run validate
npm run render -- 05-blueprint
```

For the delivered silent BT.709 master, use the renderer's standard output flags:

```sh
npm run render -- 05-blueprint --muted --color-space=bt709
swift templates/05-blueprint/qa.swift
```

The explicit mute removes the silent AAC track (and its encoder padding); BT.709
selects standard video color metadata. No shared toolchain changes are needed.
The optional QA helper uses macOS AppKit, Swift, and `ffmpeg`/`ffprobe` on PATH.
It checks the final file and creates a labeled 36-frame contact sheet and a
1920×1080 poster from the encoded MP4. Its sample indices target the scene table
below; update those indices if you change scene timings.

- `config.ts` contains the main copy, scene durations, palette, entrance timings,
  and source recording offset. Durations are in seconds, at 30 fps.
- `index.tsx` contains the drawing components and secondary technical annotations.
  `Phone` describes its non-destructive source crops in source-image pixels.
- `template.json` must track the total of the configured scene durations.
- Output: `out/05-blueprint.mp4`, H.264, CRF 18, 1920×1080, 30 fps.
- No runtime network assets, added dependencies, or modified shared files.

## Scene plan and motion budget

Hard cuts separate scenes. Every frame has the static drafting paper and frame;
cuts intentionally reveal the next drawing, rather than fading through black.
Entrances use cubic ease-out; moves use cubic ease-in-out. All state derives from
Remotion frames. Construction lines draw in 12 frames (0.4 seconds). Staggered
lines use that same motion family. There are never more than two concurrent
motion families. No idle oscillation or CSS animation.

| Time | Primary copy | Source / construction | Motion families |
| --- | --- | --- | --- |
| 0–5 s | Devin. Now native. | Exploded session and native phone planes | Group opacity/translation entrances; line drawing |
| 5–9 s | Manual QA. Or a CI wait. | Prior manual checks and 20+ min CI context | Group entrance; dimension drawing |
| 9–15 s | Build it. Run it. | Managed Mac workspace backing plane; native phone | Group entrances then plane assembly; line drawing |
| 15–21 s | Tap. Type. Scroll. | Wisp native screenshot, input leader, action index | Group entrance then illustrative input emphasis; line drawing |
| 21–27 s | Reproduce. Fix. Retest. | Wisp screenshot and metadata finding annotation | Group entrance and discrete step emphasis; repair-loop drawing |
| 27–33 s | Review the recording. | Real web QA clip in the assembled schematic | Source video playback; corner/dimension drawing (type stays still) |
| 33–39 s | Working app. In view. | Front-facing native iPhone and price statement | Group entrance/rotation; line drawing |
| 39–44 s | Build. Run. See it. | Supplied white Devin logo, macOS + iOS | Group translation entrance; logo dimension drawing |

The action index and repair index are scene progress, not execution time.
Primary headings and the end logo remain visible from each cut's first frame;
their entrance is a small translation, so no cut leaves an empty canvas.
Input rings and exploded arrangements are illustrative annotations, not newly
captured product interactions. The Wisp image is not scrolled or edited into a
fabricated result. The repair annotation makes clear no new test result is implied.

## Source provenance and honest scope

Shared original assets from `public/assets`:

- `devin-web-13.png` (2982×1620): actual Devin macOS session screenshot. Full
  screenshot shown as the rear isometric UI plane. Text is source context;
  editorial copy carries the readable story.
- `devin-web-18.png` (2978×1626): supplied native iPhone Simulator review.
  `Phone` crops a 590×1200 rectangle at (678, 226), retaining the whole phone
  and original UI. Used in hook, build, and outcome. Cropping is uniform scaling,
  followed by the clearly schematic plane projection.
- `devin-web-10.png` (2990×1624): supplied Wisp Simulator feature check.
  Native phone crop is 590×1200 at (682, 226). The original reports **12 passed,
  3 failed, 2 untested**, including absent model context/pricing metadata.
  No all-passing claim is made. The card in the repair scene refers to that
  actual finding, not to an invented successful fix.
- `devin-testing-2.mp4` (1918×1080, 30 fps, 59.133 s): **real generic web-app
  QA**, used from source time 15–21 s with muted `OffthreadVideo`. It is
  explicitly labeled “SOURCE RECORDING / WEB APP QA.” This is not iOS footage,
  and its results are not attributed to any of the native examples.
- `logo-white.png` and `mark-white.png`: supplied logo and mark, used faithfully,
  with their native aspect ratio on the dark background.

Native scenes visibly say “ILLUSTRATIVE WORKFLOW / SUPPLIED iOS STILLS.”
No physical-device support, simultaneous interactive devices, signing, shipping,
App Store workflow, or measured speedup is implied. “20+ min” is the prior CI
context in the supplied brief; “Same price as Linux VMs” is the launch fact.
The video does not verify the product anew. The source recording's incidental
audio is muted; this direction is intentionally silent.

## Brand adaptation and limitations

Reference: the coordinator's inspected Figma `Devin` file, node `0-1`, with
observed values recorded in the shared README and `shared/brand.ts`.
This is a technical-drawing adaptation of that reference: generous 32/64/96
spacing, restrained weight, thin frame borders, dark contrast, and a cyan
schematic accent derived for this direction. It is not a marketing-site clone.

NB International Pro and Inter font binaries were not supplied. Display type
uses `brand.displayFont`: **Helvetica Neue on this macOS render**, with Arial and
sans-serif fallbacks. Technical annotations use `brand.monoFont`: Menlo when
SFMono-Regular is not available, then Consolas/monospace. System availability
can change glyph metrics on another OS; inspect the contact sheet after edits.
No external fonts are fetched.

The screenshots carry source UI detail which is intentionally secondary at
video scale. The primary copy and sparse leaders are the readable content.
The isometric transforms deliberately project whole planes without stretching
the underlying asset within the plane.

## Offline media QA

Run all four required npm commands, then inspect exported frames at the center
of all eight scenes and before/at/after cuts. Include entrance and plane-assembly
frames. Extract the full-frame poster from the final MP4 and produce a labeled
contact sheet in ignored `out/`, with no media committed. `ffprobe` must confirm
H.264, yuv420p, 1920×1080, 30 fps, 1320 frames, 44 seconds. Upload MP4, full-frame
poster and contact sheet through attachments. This is offline rendered-media
inspection; no browser UI-testing workflow is involved.
