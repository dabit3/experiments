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
