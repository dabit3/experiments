# 12 · Musical Score

A silent, 40-second launch montage with the structure of an editorial score:
three narrow horizontal tracks; five equal-width chapters; a playhead that
travels to a chapter and **parks**; small square cues at observed source events.
There are no seconds, tempo measurements, musical notes, audio visualizers, or
overlapping execution claims. The separate-example disclaimer stays on the score.
The closing gesture resolves the three tracks to a single terminal bar beside
the supplied launch CTA.

Product captions and media remain still during demonstrations. Only the narrow
score reacts to cues. The original iPhone/iPad screenshots are held still and cut
between; they do not pretend to be Simulator recordings. Agent and Web QA source
clips run at 1×. The introduction and closing are typographic title compositions.

## Setup / render

From `product-launch-videos/`, use the shared Node 22.12+ scaffold:

```sh
npm ci
npm run assets:setup -- /absolute/path/to/shared-assets.zip
npm run assets:check
npm run templates:list
npm run render -- --template 12-musical-score
npm run still -- --template 12-musical-score --frame 450
npm run still -- --template 12-musical-score --frames 0,60,150,300,450,525,660,765,960,1050,1062,1140
npm run contact-sheet -- out/12-musical-score
ffprobe -v error -select_streams v:0 \
  -show_entries stream=width,height,r_frame_rate,nb_frames:format=duration \
  -of json out/12-musical-score/12-musical-score.mp4
```

Only this directory is producer source. Original recordings, images, fonts, and
renders are ignored. No individual PR or public deployment belongs to this stage.

## Editable controls

`config.ts` exports the typed `MusicalScoreConfig`; `index.ts` exposes the controls
to the shared gallery. Rendering accepts a **complete** `{ "config": ... }` object
with `--props`; it does not merge a partial object. Start from the generated
`out/12-musical-score/resolved-props.json`.

| Input | Effect |
| --- | --- |
| `copy` | Opening, benefit, feature, five product captions, pricing, CTA, URL |
| `durations` | Seven scene lengths in seconds; metadata and sequence starts recalculate |
| `media` | Original asset, contain/cover, anchor X/Y, optional source-pixel crop; video source start |
| `brand.colors` | Canvas, ink, secondary text, white, media mat |
| `brand.typography` | NB International / companion mono family, sizes, line heights, tracking |
| `brand.spacing.titleGap` | Vertical title, supporting statement and CTA spacing |
| `layout.margin`, `gutter`, `captionHeight` | Outer margin, title/sidebar gap, reserved caption region |
| `layout.grid.mediaTop`, `mediaHeight`, `scoreTop` | Product and contextual-strip geometry |
| `score.tracks` | Three editable track labels |
| `score.chapters` | Per-scene chapter label and track index, 0–2 |
| `score.cues` | `{scene, atSeconds, label}`; local scene time, not an execution metric |
| `score.fontSize`, `rowHeight`, `labelWidth`, `barInset`, `ruleOpacity` | Score typography, track spacing, label column, deliberate bar gaps, line weight |
| `score.label`, `context`, `introIndex`, `closingIndex` | Editorial context and title indices |
| `motion.entranceFrames` | Initial score draw and title settle |
| `motion.playheadTravelFrames` | One short move per chapter, followed by a long parked hold |
| `motion.cueAccentFrames`, `cueAccentSize` | Decaying square accent outside product controls |
| `motion.resolveFrames` | Convergence of tracks into the closing bar |
| `motion.iphoneSplit` | Fraction of the iPhone scene allocated to the first still |
| `sound` | Optional local sound file, enabled flag, gain, cue duration; default off |

Five chapters have equal visual widths independently of duration. Bar widths
never claim elapsed or measured execution time. Only one chapter is active.
The source videos' trim lengths must stay within their real duration; the shared
component rejects overruns rather than changing playback speed or looping.
Cue labels should identify what is visible. The sample cues are macOS selected,
agent menu open at source 1s, static Simulator examples, the Web QA new-ticket
form at source 3.5s, and the iPad example. Do not relabel them as completed tests.

### Optional sound accents

No soundtrack or sound asset is bundled. Put an authorized short local sound
in ignored `public/assets/`, set `sound.enabled=true`,
`sound.asset="assets/your-accent.wav"`, and adjust gain/length. The default shared
render wrapper intentionally mutes all audio. To include optional cues, use:

```sh
npx remotion render src/templates/12-musical-score/entry.tsx MusicalScore \
  out/12-musical-score/with-accents.mp4 --props /absolute/path/to/complete-props.json
```

This is still frame-driven; sound cues are triggered at the same editable
observed-event offsets as visual accents. The sample remains silent-friendly.

## Validation

Run `npm run lint`, `npm run typecheck`, `npm test`, and `npm run build`.
Use full-size stills to inspect title entrance, every cut, source report counts,
logo proportions and captions. The poster is an actual iPhone scene frame.
The contact sheet contains genuine rendered composition frames.

The default sample measured **1920 × 1080, 30/1 fps, 1200 frames, 40.000 seconds**
using `ffprobe`; complete FFmpeg decode passed. Lint, TypeScript, eight shared
TypeScript tests, three shared Python tests and Vite build passed. Vite reports
the dependency's harmless ignored `"use client"` directive.

Twenty-four representative full-resolution frames were inspected, including
both sides of the iPhone cut, each product entry, observed video cues and closing
track convergence. Closing track labels finish fading out before the resolution
label fades in. Twelve selected rendered frames form the
deliverable contact sheet. The poster is composition frame 450.

To reproduce the non-default edit:

```sh
npx tsx src/templates/12-musical-score/make-edit-props.ts
npm run render -- --template 12-musical-score \
  --props out/12-musical-score/edited-props.json \
  --output out/12-musical-score/edited-validation.mp4
```

This diagnostic changes all seven durations to **1, 1, 2, 2, 4, 1, 1 seconds**,
the opening and environment caption, CTA, track labels, playhead timing, and
iPhone still split. Its full render measured **360 frames / 12.000 seconds** at
1920 × 1080 and 30/1 fps. Extracted frames verified the changed title, caption,
and tracks. Short diagnostic holds are intentionally not the delivered sample.
Because the shared CLI writes metadata for the latest run, render a default
still afterward to restore default `metadata.json` and `resolved-props.json`.

## Attribution and limits

See `attribution.json` for the exact default edit, crop coordinates and font
mapping, and the shared `MEDIA-ATTRIBUTION.md` for original provenance.
The environment and agent crops retain their relevant menus and composer
context. Both iPhone stills, Web QA, and iPad preserve complete reports.
These are separate sessions, not one causal app-building sequence.
No customer, App Store, TestFlight, physical-device or signing claims are added.
The optional user-provided sound path is implemented but not exercised in the
silent sample; the shared render command always mutes it. Full report text is
retained at original aspect ratio; use the 1080p video/poster for reading detail,
not the small contact-sheet thumbnails.
