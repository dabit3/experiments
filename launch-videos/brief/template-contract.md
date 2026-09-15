# Template contract

Every one of the 20 templates is a self-contained Remotion project that follows the same
contract so they can be compared, rendered, and reused the same way.

## Location & stack

- Directory: `launch-videos/templates/NN-slug/` (e.g. `01-swiss-grid`). Two-digit index,
  kebab-case slug from `brief/templates.md`.
- Remotion 4.x, React 18, TypeScript, Zod (`@remotion/zod-types`) for the props schema.
  No CSS frameworks, no UI kits, no third-party animation libs. Use Remotion primitives
  (`useCurrentFrame`, `interpolate`, `spring` only where the direction allows, `Sequence`,
  `OffthreadVideo`, `Img`, `staticFile`).
- `remotion.config.ts` must call `Config.setPublicDir("../../assets")` so all media is
  referenced as `staticFile("recordings/androidios.mp4")` etc. Do not copy assets into
  the template.
- Each template has its own `package.json` (name `@launch-videos/NN-slug`), `tsconfig.json`,
  `.gitignore` (node_modules, out). Scripts: `dev` (remotion studio), `render`
  (`remotion render Launch out/launch.mp4`), `still` (`remotion still Launch out/poster.png --frame=<hero frame>`),
  `typecheck` (`tsc --noEmit`), `lint` (`eslint src`).

## Composition

- Composition id `Launch`, 1920x1080, 30fps. Default duration for the test render is
  45s (1350 frames); `durationInFrames` must be derived from the sum of editable scene
  durations via `calculateMetadata`.
- Props (`src/schema.ts`, exported as `launchPropsSchema` + `LaunchProps`):
  - `brand`: colors, `fontFamily`, `monoFontFamily`, `logoLight`, `logoDark` — defaults from `brief/brand.md`.
  - `content`: `featureName`, `eyebrow`, `headline`, `subhead`, `captions[]`, `useCases[]`,
    `stages[]`, `cta {label,url}`, `outroLine`, `speedBadge` — defaults from `brief/launch-mac-vm.md`.
  - `media`: named slots (`hero`, `pick`, `work`, `simulator`, `verify`, `result`, ...),
    each `{ src, kind: "image"|"video", startFrom?, crop?: {x,y,w,h} (fraction 0-1), playbackRate? }`.
  - `scenes[]`: ordered `{ id, durationInFrames, ...direction-specific layout fields }`.
  - Any direction-specific knobs (grid columns, camera path, panel split, etc.).
- `src/Root.tsx` registers `Launch` with `defaultProps` = the Mac VM test launch, and
  optionally a second composition `Poster` (still) using the same props.

## Rules the video must follow

- Product UI is shown flat, front-facing, and pixel-preserved (crop/scale only; no skew,
  no recolor, no fabricated UI states). Text in footage must stay legible: never scale a
  1920px recording below ~55% of frame width while it is the subject.
- Only claims from `brief/launch-mac-vm.md`. Captions describe what is on screen.
- Brand from `brief/brand.md`. One accent color. Inter (via `@remotion/google-fonts`) as
  the deterministic fallback for NB International Pro; expose `brand.fontFamily`.
- Every hold on a result lasts >= 2.5s. No audio track in v1.
- The direction-specific "avoid" list in `brief/templates.md` is binding.

## Deliverables per template

1. The template project (above) with `README.md`: direction summary, a scene-by-scene
   table (scene id, default duration, what it shows), the editable props, and how to
   swap in a different launch (change `defaultProps` or pass `--props`).
2. `out/launch.mp4` rendered from the default props, and `out/poster.png` — both are
   git-ignored; attach them to your final message instead.
3. Three still frames (opening, mid-demo, closing) as PNGs attached to the final message,
   and embedded in the PR description.
4. `npm run typecheck` and `npm run lint` pass. `npm run render` completes.

## What NOT to do

- Do not edit anything outside your template directory (no changes to `assets/`, `brief/`,
  the root README, or other templates).
- Do not add a top-level workspace/monorepo config.
- Do not vendor fonts or download stock media. Do not add audio.
