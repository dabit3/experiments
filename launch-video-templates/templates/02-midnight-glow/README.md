# 02 — Midnight Glow

A 42-second, silent, 1920 × 1080 / 30 fps launch film. Near-black space,
restrained blue/purple radial light, faint headline bloom, one-pixel UI borders,
and edge-entering pills connected to UI with hairlines.

## Edit and render

From `launch-video-templates`:

```sh
npm ci
npm run lint
npm run typecheck
npm run validate
npm run render -- 02-midnight-glow
```

The `Launch` composition is registered by `index.tsx`. The render helper writes
`out/02-midnight-glow.mp4` with H.264, CRF 18 and concurrency 2. The shared
command requests yuv420p; on this Mac, ffprobe reports full-range yuvj420p.
There are no extra packages or remote runtime assets.

Edit primary copy, scene durations, palette, labels, the source-video in-point
and transition duration in `config.ts`. Scenes follow their array order;
start frames are calculated from the durations. Keep the sum of scene seconds
equal to `template.json`'s `durationSeconds`. `index.tsx` contains layout,
representative workspace rows, source crop coordinates, and callout positions.
Changing a source crop preserves its aspect ratio: `Crop` uniformly scales the
entire source image inside an explicitly sized viewport.

## Scene map

Times below are scene starts. Scene cuts cleanly separate the ideas. Every
scene after the hook has a 0.6-second ease-out entrance: 22px upward settling
and opacity from 55% to 100%. Copy from different scenes never overlaps, and
no transition introduces an empty frame. The final end card holds without
fading to black.

| Time | Primary idea | Media | Motion families |
| --- | --- | --- | --- |
| 00–05 | Devin goes native. | Large cropped iPhone from `devin-web-18.png` | Static opening; edge pill reveal |
| 05–09 | Build. Wait. Test by hand. | Editorial 20+ minute prior-CI context | Scene opacity/translate only |
| 09–15 | Build and run. On macOS. | Representative workspace + real iPhone still | Scene reveal; edge pills. Task focus changes are hard cuts |
| 15–21 | Tap. Type. Scroll. | Wisp iPhone from `devin-web-10.png` | Scene reveal; edge pills. Scroll gesture moves only after scene reveal finishes |
| 21–27 | Reproduce. Fix. Retest. | Actual mixed-result Wisp report crop | Scene reveal; edge pill. Workflow focus changes are hard cuts |
| 27–33 | See what happened. | Actual web-app QA video, source 11–17s | Scene reveal/edge pill are staggered; source video playback |
| 33–38 | A working app. In your session. | Large cropped iPhone from `devin-web-18.png` | Scene reveal; edge pill |
| 38–42 | Build. Run. See it. | Supplied white Devin logo | Scene reveal only; static hold |

All animation is derived from Remotion frame numbers. Entrances use cubic
ease-out; the illustrative scroll movement uses cubic ease-in-out. There are no CSS
animations, random values, clocks, decorative looping particles, or audio.
The static glows and text shadows never pulse. At most two families run
concurrently. In the source-video scene the callout starts after the entrance
ends, so playback has at most one overlay animation.

## Provenance and truthful staging

- **`public/assets/devin-web-18.png`:** supplied native iPhone Simulator
  review screenshot. Region `[682,237,579,1184]` isolates the phone at uniform
  scale. Rounded clipping removes the desktop corners. This is a still, not
  footage recorded for this template.
- **`public/assets/devin-web-10.png`:** supplied Wisp Simulator checks. Region
  `[687,237,579,1184]` isolates the iPhone for the interaction scene. Region
  `[1950,142,1040,445]` shows the real mixed-results summary for reproduce/fix/
  retest. Its passed, failed and untested counts are retained; no all-passing
  claim or fabricated fixed outcome is added.
- **`public/assets/devin-testing-2.mp4`:** actual supplied 1918 × 1080 web-app
  QA recording. Source 11–17 seconds shows a web ticket-delete flow and review
  annotations. It is presented at its full aspect ratio in a frame labeled
  **“Actual recording · web-app QA”** with a second line identifying it as a
  generic insert. It does not depict iOS testing, Mac VM selection, or a new
  test run. Incidental audio is muted via `OffthreadVideo`.
- **`public/assets/logo-white.png` and `mark-white.png`:** supplied artwork,
  used intact, uncropped, at intrinsic aspect ratio on dark backgrounds.
- `devin-web-11/12/13/14.png` and source-video samples at 12 and 16 seconds were
  inspected during selection. They are not all used in the final film.

The dark native workspace and task rows are representative motion UI.
Callouts and the scroll gesture indicate supported actions; they do not
pretend a still screenshot is fresh live iOS footage. Native scenes visibly
say **“Illustrative workflow”**. The reproduce/fix/retest sequence describes
the capability and intentionally does not pretend that the supplied Wisp
failures have been fixed. The hook/outcome's “live iPhone” wording describes
the launch capability, while the accompanying label identifies the still.

The `20+` figure is the user's prior CI context, not a benchmark or timing
claim about the depicted apps. Task highlights indicate narrative workflow
progress, not elapsed execution time. Pricing uses only the supplied claim,
“Same price as Linux VMs.”

## Brand, type and limits

This adapts the coordinator-inspected Cloud/Main Figma frames from
<https://www.figma.com/design/evS5ExlrnLrUCMPm395OHw/Devin?node-id=0-1>.
The original Socials file is not used. Blue `#1971c2`, purple `#956cde`, green
`#0ca678`, compact letterspacing, 1px borders and generous 8px-derived spacing
come from `shared/brand.ts`; lavender text is a lighter on-dark adaptation.

NB International Pro and Inter font binaries were not supplied. The shared
display stack falls back to **Helvetica Neue** on the rendering Mac, then
Arial/sans-serif elsewhere. Terminal UI uses SFMono-Regular/Menlo/Consolas.
No font is fetched remotely. A different renderer OS may have different
fallback metrics; recheck text fit if rerendering elsewhere.

This is an intentionally silent, editable launch template, not a product
screen capture tutorial. It does not claim device hardware, distribution,
signing or unsupported native features. Only one iPhone is shown per scene.
Underlying small app text is source-image detail; the large headline and
callout carry the narrative at video scale.

## Render QA

Run the four required checks above, then:

```sh
ffprobe -v error -select_streams v:0 \
  -show_entries stream=codec_name,width,height,r_frame_rate,pix_fmt,nb_frames:format=duration \
  -of json out/02-midnight-glow.mp4
```

Poster selection: 3.0s (frame 90), full frame. Contact-sheet selection includes
all eight story beats, each interaction sub-beat, the source-video insert,
the final held logo, and frames immediately before, during and after every
transition. Rendered MP4/PNG outputs belong only in ignored `out/`.

The shared renderer's first full render produced 1,260 H.264 video frames
(42.000s) and a silent AAC stream with 48ms padding (container 42.048s).
`volumedetect` found both mean and maximum at −91 dB. These are documented
shared-renderer encoding characteristics; no shared files or dependencies
were changed to suppress them.
