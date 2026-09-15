# Additive template contract · version 1

## Ownership

A producer owns exactly one `src/templates/<slug>/` directory, where `<slug>`
starts with its assigned two-digit number from `01` to `20`. Use the slug assigned
by the coordinating workflow (for example, `01-swiss-grid`, `20-pure-product`).
Do not edit shared files, package files, other templates, or a global registry.
Do not open a producer PR. Push your own branch and return the commit for collection.

Every directory contains these exact filenames:

```text
src/templates/<slug>/
  entry.tsx         # registerRoot(template.Root); independent Remotion entry
  index.ts          # named `template` descriptor export; NO registerRoot side effect
  Template.tsx      # independently designed React composition
  config.ts         # complete editable default config, including own motion controls
  manifest.json     # discovery metadata, schema below
  attribution.json # timeline/source map for this edit, schema below
  README.md         # direction, inputs, render commands, results, limitations
```

You may add helper components, tests and locally authored code within your
directory. Binary assets remain in ignored shared `public/assets/`; artifacts
remain in ignored `out/<slug>/`. Do not commit any files from the original ZIP.
Read your complete direction prompt from the installed prompt document.

## Minimal wiring

`manifest.json` is data only:

```json
{
  "schemaVersion": 1,
  "slug": "01-swiss-grid",
  "name": "Swiss Grid in Motion",
  "description": "A concise description of the actual direction.",
  "compositionId": "SwissGrid"
}
```

The slug must match its directory. Remotion IDs allow only letters, numbers, and
hyphens; IDs are unique across all collected templates. Do not use underscores.

`config.ts`:

```ts
import {defaultLaunchConfig, type LaunchConfig} from '../../shared';

export type DirectionConfig = LaunchConfig & {
  motion: {panelRevealFrames: number; panelTravel: number};
};

export const config: DirectionConfig = {
  ...structuredClone(defaultLaunchConfig),
  motion: {panelRevealFrames: 18, panelTravel: 96},
};
```

`Template.tsx` exports `Template`, accepting `{config: DirectionConfig}`. Design
your composition there. The example names above illustrate inputs, not a design
implementation. There is deliberately no universal scene shell.

`index.ts`:

```ts
import {defineTemplate} from '../../shared';
import manifest from './manifest.json';
import {config} from './config';
import {Template} from './Template';

export const template = defineTemplate({
  ...manifest,
  schemaVersion: 1,
  Component: Template,
  defaultConfig: config,
  controls: [
    {
      path: 'motion.panelRevealFrames',
      label: 'Panel reveal',
      type: 'number',
      description: 'Frames used to uncover the surrounding panel.',
      min: 0, max: 60, step: 1,
    },
  ],
});
```

`entry.tsx`:

```tsx
import {registerRoot} from 'remotion';
import {template} from './index';
registerRoot(template.Root);
```

`defineTemplate` supplies the font gate, independent Composition root, a
default-config `Preview` component, `metadata`, `defaultConfig`, and `controls`.
It derives duration with `timelineDuration(config.durations, 30)` on both metadata
selection and render. `Root` is only registration; it does not constrain layouts.
The gallery consumes the structural `GalleryDescriptor` interface and uses
`Preview` plus `metadata`. It never imports `entry.tsx`.

### Inputs

The baseline `LaunchConfig` has:

- `copy`: all approved shared strings, including benefit, feature, captions,
  pricing, CTA and URL.
- `durations`: seconds for `opening`, `environment`, `agent`, `iphone`, `webQa`,
  `ipad`, `closing`. Defaults: **4, 5, 4, 9, 7, 6, 5**, totaling 40 seconds.
- `brand`: colors, font families, heading/body size, tracking, line height, spacing.
- `media`: `logo`, `environment`, `agent`, `iphone` (two ordered stills),
  `webQa`, `ipad`. Each has a typed `asset` filename and `framing`; videos also
  have `sourceStartSeconds`.
- `layout`: margin, gutter, padding, captionHeight, plus `grid` numeric positions.
- `motion`: direction-specific controls; specialize its type and document each
  exposed field in `controls`. Control metadata paths refer to config paths.

You can extend `LaunchConfig` with more JSON-serializable inputs. Keep the baseline
fields so the collector and sample durations stay consistent. No functions,
random generators, file handles or React elements in the config.

Each preview uses its editable default config. The gallery shell lists inputs but
does not provide interactive form widgets. Render/still accepts `--props` pointing
to a **complete** `{"config": ...}` JSON object; partial props are not deeply merged.

## Rendering primitives

Import shared utilities from `../../shared` or their individual source files:

| File | Exports / role |
| --- | --- |
| `assets.ts` | `assets`, `assetPath`, `logos`, `mediaNotes`, typed image/video IDs |
| `asset-manifest.json` | SHA-256, byte count, dimensions, durations/fps of originals |
| `tokens.ts` | `brand`, `VIDEO` (1920 × 1080, 30 fps) |
| `fonts.tsx` | `BrandFonts`, `loadBrandFonts`; already used by `defineTemplate` |
| `config.ts` | `LaunchConfig`, `defaultLaunchConfig`, media selection types |
| `timeline.ts` | `makeTimeline`, `timelineDuration`, `frames`, sample copy/durations |
| `geometry.ts` | `Framing`, `Crop`, `contain`, `mediaGeometry` |
| `media.tsx` | `SourceImage`, `SourceVideo` |
| `motion.ts` | `progress`, `easeInOut`, `mix`, `fadeInOut`, `rectangleReveal` |
| `contract.tsx` | `defineTemplate`, `TemplateProps`, `GalleryDescriptor`, control types |

`SourceImage` requires `asset`, `width`, `height`. `SourceVideo` also requires
`sourceStartSeconds` and `durationInFrames`. Wrap either in any layout or transform.
Source dimensions always retain their aspect ratio. `framing` supports:

```ts
{
  fit: 'contain', // or 'cover'
  anchorX: 0.5,  // 0..1
  anchorY: 0.5,  // 0..1
  crop: {x: 0, y: 0, width: 2988, height: 1622} // optional ORIGINAL source pixels
}
```

Default to contain for reports; cropping a report can conceal failed/untested
counts, so inspect the result. Source-pixel crop windows are independently clipped,
including for contain, and reject out-of-bounds coordinates. Animate surrounding
frames or a composed still's placement, not fabricated internal application state.

### Source time is independent of destination time

```tsx
const timeline = makeTimeline(config.durations, 30);
const agent = timeline.find((scene) => scene.id === 'agent')!;

<Sequence from={agent.from} durationInFrames={agent.durationInFrames}>
  <SourceVideo
    {...config.media.agent}
    width={1600}
    height={900}
    durationInFrames={agent.durationInFrames}
  />
</Sequence>
```

The destination `Sequence` sets local frame zero; the explicit source offset
always remains `sourceStartSeconds`. Moving that sequence must not alter its trim.
The component maps trim seconds into **composition frames**, sets `trimBefore` /
`trimAfter`, enforces **1×** playback, and fails on source overrun. Do not use the
source video's fps to convert Remotion trims. If splitting a clip across separate
sequences, explicitly add the consumed source seconds to the later part's offset.

`devin-testing-2.mp4` always gets a 48px reserved footer with **Web QA example**.
Its `width`/`height` describe the entire component including the footer. `labelHeight`
(minimum 40) and `labelStyle` allow placement styling; keep it legible and persistent.
The label is outside the source viewport, never over a source control. If it must
sit on a different surface, compose the whole source component within that surface.

Rendering uses `OffthreadVideo`; the Player uses Remotion's preview behavior.
Both honor the same trims. Do not replace the shared video component with raw
video elements unless the parent explicitly approves a necessary contract extension.
Keep every source action at 1×. An extended scene must fit within the actual clip.

## Shared edit and attribution

Use the same media order and default copy across all directions:

| Scene | Output seconds | Source |
| --- | --- | --- |
| opening | 0–4 | supplied logo, opening, main benefit |
| environment | 4–9 | `devin-web-4.png` |
| agent | 9–13 | `agent-selector-cloud.mp4`, source **0–4** |
| iphone | 13–22 | `devin-web-14.png` then `devin-web-18.png` |
| webQa | 22–29 | `devin-testing-2.mp4`, source **0–7**, Web QA example |
| ipad | 29–35 | `devin-web-19.png` |
| closing | 35–40 | supplied logo/stable result, pricing, CTA and URL |

The iPhone still split can vary slightly by direction; preserve readable holds
and the reports. The sample is a montage from separate sessions. Do not imply
causality between unrelated apps or Simulator motion from the two web recordings.

`attribution.json` contains a JSON array of records, one per use:

```json
[
  {
    "scene": "agent",
    "asset": "agent-selector-cloud.mp4",
    "outputSeconds": [9, 13],
    "sourceSeconds": [0, 4],
    "treatment": "1x clip, contained; caption reserved above footage.",
    "requiredLabel": null
  }
]
```

For stills, `sourceSeconds` is null. For the testing recording,
`requiredLabel` is `"Web QA example"`. List supplied logos and fonts too, with
their whole-use output ranges. Describe any crop in `treatment` with source
coordinates. `MEDIA-ATTRIBUTION.md` supplies shared provenance and content limits;
the tracked asset manifest provides exact original-file hashes.

## Acceptance and collection

```sh
npm run templates:list
npm run lint
npm run typecheck
npm test
npm run render -- --template <slug>
npm run still -- --template <slug> --frame 150
npm run still -- --template <slug> --frames 0,150,330,450,600,750,960,1140
npm run contact-sheet -- out/<slug>
ffprobe -v error -select_streams v:0 \
  -show_entries stream=width,height,r_frame_rate,nb_frames:format=duration \
  -of json out/<slug>/<slug>.mp4
```

Inspect representative original-size frames for fonts, sharp UI, proportional
logos, clipping, blank media, captions and required report counts. Expected
default output: 1920 × 1080, 30 fps, 1200 frames, 40 seconds. Preserve image
aspect ratios and video source speed. UI testing and public deployment are not
part of this producer task.

Return the pushed source branch and commit, actual attachment URLs for MP4,
poster and contact sheet, checks, and limitations. The collector cherry-picks
producer commits into a collection branch, runs the same checks and builds the
gallery; it creates the single final PR. Collectors can enumerate
`src/templates/*/manifest.json` or use `npm run templates:list`; the Vite glob
finds each corresponding `index.ts` descriptor without a shared registry.
