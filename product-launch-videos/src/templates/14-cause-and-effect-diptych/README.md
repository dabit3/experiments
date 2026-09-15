# 14 — Cause-and-Effect Diptych

A refined moving seam connects an actual test step and its recorded observation
to the Simulator still from **that same source screenshot**. The divider gives
the Simulator more room, returns to comparison, and dissolves into the complete
source. The iPad result eventually occupies the full canvas before the
quiet two-column pricing/CTA card.

The default layout removes editorial numbering, panel labels and the recording
rail, enlarges captions and media, and uses one-pixel rules at 14% opacity.
The videos remain complete, normal-speed recordings. In Web QA the recording already contains the genuine
side-by-side report. There are no invented counterpart screens or comparisons
between unrelated sessions. Neither video is described as Simulator footage.

## Run

From `product-launch-videos/`, install and verify the shared assets as described
in the root README (`npm ci`, `npm run assets:setup -- /absolute/shared-assets.zip`).

```sh
npm run assets:check
npm run templates:list
npm run lint
npm run typecheck
npm test
npm run build
npm run render -- --template 14-cause-and-effect-diptych
npm run still -- --template 14-cause-and-effect-diptych --frame 180
npm run still -- --template 14-cause-and-effect-diptych \
  --frames 0,60,180,330,450,570,750,960,1065,1150
npm run contact-sheet -- out/14-cause-and-effect-diptych
ffprobe -v error -select_streams v:0 \
  -show_entries stream=width,height,r_frame_rate,nb_frames:format=duration \
  -of json out/14-cause-and-effect-diptych/14-cause-and-effect-diptych.mp4
```

The independent Remotion entry is `entry.tsx`; composition ID is
`CauseAndEffectDiptych`. Default duration is calculated from the seven scene
durations: **4 / 5 / 4 / 9 / 7 / 6 / 5 seconds**, at 1920 × 1080 / 30 fps.
The iPhone scene contains two ordered still holds.

## Edit

`config.ts` is the primary authoring surface. For render props, copy the complete
`out/14-cause-and-effect-diptych/resolved-props.json`, change values, and pass
`--props /absolute/edited-props.json`. Partial objects are not deep-merged.

| Config | Purpose |
| --- | --- |
| `copy` | Approved launch copy, all scene captions, pricing, CTA and URL |
| `durations` | Seven scene durations in seconds; metadata and scene boundaries recalculate |
| `media` | Source assets, source trim seconds, fit and anchors |
| `pairings.environment`, `pairings.iphone[0/1]`, `pairings.ipad` | Same-source left/right crop windows in original pixels, literal labels, provenance note, comparison/active ratios |
| `labels` | Optional panel/rail labels; required Web QA label is protected by shared SourceVideo |
| `brand.colors` | Canvas, ink, white, secondary text and media mat; never recolors source pixels |
| `brand.typography` | Original font family, heading/body size, tracking and heading/body line height |
| `layout` | Margin, gutter, media padding, header height, panel-label and footer heights |
| `motion.dividerFrames` | Deterministic synchronized seam travel, capped to 7% of each still hold |
| `motion.activeAt / balancedAt / unifyAt` | Normalized within each still hold; active result, comparison, complete-source cues |
| `motion.iphoneSwitchAt` | Fraction of iPhone scene devoted to the first still |
| `motion.videoRailRatio` | Optional rail share; default `0` removes the rail and maximizes the recording |
| `motion.openingSplit` | Opening and CTA dividing line as canvas-width fraction |
| `motion.closingCtaAt` | Closing fraction held on full-canvas result before CTA |
| `motion.shutterFrames` | Editorial rule reveal length; never hides source-video actions |
| `motion.dividerWidth` | Seam weight in output pixels |
| `motion.dividerOpacity` | Line opacity; default `0.14`, or `0` to remove rules |
| `motion.showPanelLabels` | Optional source labels, hidden by default; space is returned to the media |
| `motion.highlightMacOS` | Requested menu highlight correction, applied only to `devin-web-4.png` |

Each pairing resolves both sides from **one** `media` selection by design. To
replace media, replace the selection and update both original-pixel crops after
inspecting the new source. Set `rightCrop: null` to show the complete selected
image. The unification hold always respects the media selection's framing; leave
it at `contain` with no crop to preserve the complete screenshot.

Keep cue order `0 <= activeAt < balancedAt < unifyAt < 1`. Keep ratios within 0.2–0.7
and leave enough space for labels; substantial copy/geometry changes require a
new frame inspection. Video durations must fit the real source at 1× speed
(9.166667 seconds for agent, 59.133333 seconds for Web QA, minus source start).
The shared media primitive rejects overruns. The iPhone scene requires at least
two frames for its two ordered stills. Native screenshots remain still.

### Reproduce the alternate-config check

The included generator writes a complete props file with changed captions,
durations, panel ratios and synchronization timing. It asserts the resulting
18-second timeline before rendering:

```sh
npx tsx src/templates/14-cause-and-effect-diptych/write-validation-props.ts
npm run render -- --template 14-cause-and-effect-diptych \
  --props out/14-cause-and-effect-diptych/validation/props.json \
  --output out/14-cause-and-effect-diptych/validation/edited-18s.mp4
npm run still -- --template 14-cause-and-effect-diptych \
  --props out/14-cause-and-effect-diptych/validation/props.json --frame 180 \
  --output out/14-cause-and-effect-diptych/validation/edited-caption.png
```

The expected edited agent caption is “Choose your agent with Devin.” The
rendered alternate has 540 frames at 30 fps. Run the default render last when
you want `metadata.json` and `resolved-props.json` to describe the sample.

## Fidelity and attribution

`attribution.json` maps the default output timeline and source-coordinate crops.
The Afterhours Maze detail preserves **8 passed / 0 failed / 1 untested**. Report
details select the summary and first test step; the full uncut screenshot returns
at the end of each hold so lower report rows remain available. The samples come
from distinct sessions and are never presented as before/after states.

### Requested macOS menu correction

The source already checks macOS but shows Ubuntu's hover background. Per the
requested revision, `EnvironmentImage.tsx` moves the visual emphasis to macOS in
every view of that screenshot. A deterministic, source-coordinate canvas pass
clears light neutral background pixels in the Ubuntu row (`669,1078,530,75`)
and adds the matching rounded gray treatment in the macOS row immediately
below it. Original dark text, colored icons, the Ubuntu star, and the macOS
checkmark are retained. Only light neutral background/antialias pixels in those
two rows are adjusted. This is an editorial correction, not recorded interaction.

The original asset is unchanged on disk. The corrected image is generated in
memory, gated before frame capture, and shared by the crop and full-source views.
There is no extra binary to install or commit. Set `motion.highlightMacOS=false`
to render the original hover state. Other media selections bypass the correction.

Fonts and source media live only in ignored `public/assets/`. Render artifacts
live only in ignored `out/`. Nothing is publicly deployed. No soundtrack.

## Validation

Validated on 2026-09-15:

- Default full render: H.264, 1920 × 1080, 30/1 fps, **1200 frames / 40.000
  seconds**, no audio track. `ffprobe` passed; full FFmpeg decode found no errors.
- Alternate full render: 1920 × 1080, 30/1 fps, **540 frames / 18.000 seconds**.
  Changed agent caption was rendered and visually verified at frame 180.
- Poster is rendered frame 180. Contact sheet uses ten actual full-size rendered
  frames: 0, 60, 180, 330, 450, 570, 750, 960, 1065, 1150.
- Inspected product stages, original report counts, captions, proportional logo,
  original font rendering, divider states, complete-frame iPad result and CTA.
- Revised title, product captions and CTA are larger; editorial indices and
  default panel/rail labels are absent. macOS is highlighted and checked, and
  Ubuntu retains its star without the hover background.
- Shared asset verification passed for all 45 assets. Template discovery, ESLint,
  TypeScript, all 8 TypeScript tests and 3 Python tests, and Vite build passed.
  Vite prints a non-fatal dependency `"use client"` directive warning.

### Limits

Simulator material is authentic still imagery, not interaction video. Only the
agent-selector and explicitly labeled Web QA sections contain moving footage.
The source screenshots retain their original viewport clipping; the detail
panels include the summary/counts and first step, and the complete original
returns during each hold. Dense secondary UI text is smaller in complete-source
views; the diptych details provide the readable inspection view.

No browser UI testing was performed; validation is Remotion rendering and media
inspection as requested. Source footage/fonts and output artifacts are ignored
and must be installed or rendered separately. No individual PR or deployment.
