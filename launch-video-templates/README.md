# Devin launch video templates

Twenty independent motion-design directions for Devin's native macOS and iOS launch.
The compositions use React, TypeScript and Remotion. Source media is shared in
`public/assets`; each design is isolated in `templates/<number>-<name>`.

## Install and render

Requires Node.js 22 or newer.

```sh
npm ci
npm run lint
npm run typecheck
npm run validate
npm run render -- 01-keynote-minimal
```

Rendering downloads Remotion's headless browser on first use. Output is
`out/<template-id>.mp4`, H.264, 1920 × 1080, 30 fps.
To open a template in Remotion Studio:

```sh
npm run studio -- templates/01-keynote-minimal/index.tsx
```

Each template's README describes its editable copy, timing, assets, and motion system.
Keep rendered media outside git.

## Twenty directions

All compositions are `Launch`, 1920 × 1080, 30 fps. Durations below are exact
video-stream durations. Each direction's guide includes scene timestamps, source
choices, editing controls and its motion budget.

| # | Direction / editing guide | Duration | Treatment |
| --- | --- | --- | --- |
| 01 | [Keynote Minimal](templates/01-keynote-minimal/README.md) | 44 s | Quiet white stage, large type, slow push-ins |
| 02 | [Midnight Glow](templates/02-midnight-glow/README.md) | 42 s | Dark stage with mint and violet light |
| 03 | [Swiss Grid](templates/03-swiss-grid/README.md) | 40 s | Column guides and precise chapter rails |
| 04 | [Terminal Native](templates/04-terminal-native/README.md) | 42 s | Commands open into visible app evidence |
| 05 | [Blueprint](templates/05-blueprint/README.md) | 44 s | Technical drawing and exploded workflow |
| 06 | [Kinetic Type](templates/06-kinetic-type/README.md) | 40 s | Bold type cut to an original beat |
| 07 | [Bento Reveal](templates/07-bento-reveal/README.md) | 44 s | Feature tiles expand into demonstrations |
| 08 | [Editorial](templates/08-editorial/README.md) | 40 s | Magazine spreads and serif headlines |
| 09 | [Brutalist Clean](templates/09-brutalist-clean/README.md) | 40 s | Heavy type, blue accents, workflow ticker |
| 10 | [Frosted Depth](templates/10-frosted-depth/README.md) | 40 s | Translucent panels and layered parallax |
| 11 | [Warm Studio](templates/11-warm-studio/README.md) | 42 s | Warm paper and rounded product surfaces |
| 12 | [Metrics Story](templates/12-metrics-story/README.md) | 42 s | Large numerals and illustrative progress |
| 13 | [Cinematic Macro](templates/13-cinematic-macro/README.md) | 40.5 s | Letterboxed macro framing and measured moves |
| 14 | [Gradient Mesh](templates/14-gradient-mesh/README.md) | 40 s | Soft color fields around a workflow card |
| 15 | [Wireframe to Real](templates/15-wireframe-to-real/README.md) | 40 s | Wireframes resolve into interface imagery |
| 16 | [Split Timeline](templates/16-split-timeline/README.md) | 40 s | Instructions and execution in two panels |
| 17 | [Agent Graph](templates/17-agent-graph/README.md) | 42 s | Connected nodes expand into feature screens |
| 18 | [Annotated Paper](templates/18-annotated-paper/README.md) | 42 s | Paper prints, handwritten marks and notes |
| 19 | [Monochrome Accent](templates/19-monochrome-accent/README.md) | 42 s | Black and white with a single blue accent |
| 20 | [Screencast Studio](templates/20-screencast-studio/README.md) | 44 s | Session window, cursor direction and camera focus |

## Offline gallery and verification

The packaged gallery includes all twenty finished videos, posters and local
editing guides. Unzip it and open `gallery/index.html`; no server or login is
needed. Playback is manual and videos use `preload="none"`. The separate
editable-source ZIP includes the sources, lockfile, shared assets, original beat
and template helpers, without rendered output or dependencies.

For a checkout, first render the templates and run each template's documented
poster/contact-sheet helper. Store outputs as `out/<id>.mp4` and
`out/<id>-poster.png`. Then:

```sh
node scripts/validate-sources.mjs
node scripts/validate-media.mjs
node scripts/build-gallery.mjs
node scripts/validate-gallery.mjs
```

Media validation requires `ffmpeg` and `ffprobe`. It checks H.264, 1080p, 30 fps,
frame counts and exact video durations; fully decodes each file; checks posters
and audio levels; and writes `out/media-validation.json` with SHA-256 hashes.
Source checks cover local asset presence, explicit muted video inserts and
forbidden timing/network patterns. They complement manual scene/contact-sheet
review; they do not prove visual quality or native product behavior.
Gallery validation checks every local link and hashes every preview.

See [gallery instructions](gallery/README.md) for population from another media
directory or downloaded attachments. `gallery/directions.json` holds the short
summaries. To regenerate the numbered montage on macOS after producing posters:

```sh
swift scripts/make-montage.swift
```

## Design provenance

Reference: https://www.figma.com/design/evS5ExlrnLrUCMPm395OHw/Devin?node-id=0-1

Inspected Figma nodes:

- `1:5911`: Cloud hero. nbInternationalPro Regular, 64 px type/64 px line
  height, −1.7012 px tracking; 32 px vertical gaps; 16 px body with 22.4 px
  leading.
- `1:6790`: Main hero. nbInternationalPro Medium, 70.4 px type/leading,
  −2.6716 px tracking.
- `1:5923`: Cloud UI. Inter 15 px navigation, 8/16/32/48 px spacing, 10 px
  frame radii, 1 px borders at black 8%, `#fcfcfc` and `#f8f8f8` surfaces.
  Observed accents: `#1971c2`, `#0ca678`, `#956cde`, `#d5f0e8`.

`shared/brand.ts` records observed values from the website frames.
Font names are from Figma;
font binaries were not supplied. Templates use documented system fallbacks unless
their README states that an available font was bundled. Add licensed
nbInternationalPro files to use the exact display face.

## Media and claims

The user supplied 31 UI screenshots, two screen recordings, and four Devin logo
assets. Preserve their aspect ratios. Screenshots may be cropped or adapted into
representative launch UI; they are not newly recorded product tests.

`devin-testing-2.mp4` is a 59.13 s web-app QA recording, **not iOS footage**.
`model-selector-local.mp4` is a 13.47 s desktop model-selector recording,
**not the cloud Mac VM selector**. Use them only for the corresponding generic
testing/desktop moments. Native iPhone footage is represented by supplied iOS
screenshots and clearly documented motion mockups.

Launch facts come from the user's brief: Devin can build/run/test on managed Mac
VMs, interact with iOS Simulator, show a live iPhone in the session, return
recorded evidence, and use the same pricing as Linux VMs. "20+ minutes" describes
the user's prior CI context, not a measured result for these demos. Do not invent
speedups, pass rates, customer metrics, signing/shipping support, or simultaneous
interactive devices. Any shortened timeline is illustrative.

Original failed and untested native checks remain visible; none of these films
claims a newly passing retest. Native interaction is staged from supplied stills,
and every direction includes a truthfully labeled generic web-QA video insert.
All incidental source audio is muted. Nineteen directions are silent; Kinetic
Type uses only its included original synthesized beat. Silent AAC padding may
extend some MP4 containers slightly beyond their exact video-stream duration.
