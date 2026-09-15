# 07 Mission Control

A reusable 16:9 Remotion launch-video template organised like a control room:
one large **primary display**, three fixed **contextual bays** (Request, Active
work, Artifact), a **stage strip** in the header, and a **caption region** that
never moves. Whatever the viewer needs to inspect is expanded into the primary
display; the bays stay put and only change their status chip (`Standby` →
`On primary` → `Held`), so the viewer always knows where they are. The layout
holds on the PR result, then consolidates into a single hero lockup.

Nothing is fabricated: every pixel inside a panel is a supplied screenshot or
recording, only cropped and scaled. There are no charts, telemetry, radar,
progress bars, or scrolling filler. The supplied footage is sequential, so the
bays summarise stages rather than pretending work is concurrent.

## Commands

```sh
npm install
npm run dev        # Remotion Studio
npm run typecheck
npm run lint
npm run render     # -> out/launch.mp4  (1920x1080, 30fps, 45s by default)
npm run still      # -> out/poster.png  (frame 1245, the hero lockup)
```

Media is served from `launch-videos/assets/` via `Config.setPublicDir("../../assets")`
and referenced with `staticFile()`. Nothing is copied into this directory.

## Scene table (default props, 1350 frames / 45s)

| # | Scene id   | Frames | Seconds | Primary display                                   | Active bay  | Stage strip | Caption |
|---|------------|-------:|--------:|---------------------------------------------------|-------------|-------------|---------|
| 1 | `open`     | 150    | 0–5     | Title card: eyebrow, headline, subhead            | none        | none        | none    |
| 2 | `request`  | 180    | 5–11    | `devin-web-5.png`: OS picker, macOS selected        | Request     | Request     | 1       |
| 3 | `build`    | 210    | 11–18   | `devin-working-4.mp4`: Devin working in Xcode   | Active work | Build       | 2       |
| 4 | `simulate` | 270    | 18–27   | `androidios.mp4` cropped to the iPhone Simulator  | Active work | Run & test  | 3, 4    |
| 5 | `verify`   | 240    | 27–35   | `devin-testing-2.mp4`: testing/verification tab | Active work | Verify      | 5       |
| 6 | `pr`       | 150    | 35–40   | `devin-web-12.png`: "Ready to merge" PR view    | Artifact    | PR          | 7       |
| 7 | `hero`     | 150    | 40–45   | Hero lockup: logo, headline, CTA, outro           | none        | PR          | none    |

Bay defaults: Request → `devin-web-1.png` (prompt box with macOS pill),
Active work → `devin-web-9.png` (Wisp Simulator embed + test counts),
Artifact → `devin-web-12.png` (PR header, "Ready to merge").

Composition duration is derived from `scenes[].durationInFrames` via
`calculateMetadata`, so adding/removing/retiming scenes changes the length.

## Editable props (`launchPropsSchema` in `src/schema.ts`)

| Group          | What you can change |
|----------------|---------------------|
| `brand`        | All colour tokens (`paper`, `ink`, `accent`, `black`, `blackRaised`, `consoleLine`, …), `fontFamily`, `monoFontFamily`, `logoLight`, `logoDark`. |
| `content`      | `featureName`, `eyebrow`, `headline`, `headlineAccent`, `subhead`, `ctaLabel`, `ctaUrl`, `outroLine`, `speedBadge`, `captions[]`, `useCases[]`, `stages[]`. |
| `media`        | Named slots: `{ src, kind: "image" \| "video", startFrom, playbackRate, crop: {x,y,w,h} (fractions), aspectRatio }`. Add as many as you need and reference them by key. |
| `bays`         | 1–4 bays: `{ id, label, media }`. Order = top-to-bottom. |
| `statusLabels` | Text of the `standby` / `live` / `held` chips. |
| `layout`       | `safeMargin`, `gutter`, `headerHeight`, `captionHeight`, `primaryFraction`, `baysSide` (`"left"`/`"right"`), `panelRadius`, `transitionFrames`, `consolidateFrames`. |
| `scenes`       | `{ id, durationInFrames, primary: "title" \| "hero" \| <media key>, activeBay, stage, useCase, captions: [{ at, caption }], speedBadge }`. |

`crop` is expressed as fractions of the source; the source aspect ratio is
preserved and the result is fitted (`contain` in the primary, `cover` in bays).
Set `startFrom` in source frames (30fps) to choose the playback range.

## Swapping in another launch

1. Edit `defaultProps` in `src/defaults.ts`; replace `content.*` with the new
   approved copy, point `media.*` at the new screenshots/recordings under
   `launch-videos/assets/`, adjust crops/`startFrom`, and retime `scenes`.
2. Or leave the code alone and pass a JSON file:
   ```sh
   npx remotion render Launch out/launch.mp4 --props=./my-launch.json
   ```
   The JSON must satisfy `launchPropsSchema` (Remotion Studio's props panel
   validates it live).

## Fonts

Headings/body default to `"NB International Pro", "Inter", …`. Inter is loaded
from `@remotion/google-fonts/Inter`, Geist Mono from
`@remotion/google-fonts/GeistMono`. To use the licensed NB International Pro,
drop the files in `launch-videos/assets/fonts/` and load them with
`@font-face` (e.g. in `src/fonts.ts` via `staticFile("fonts/…")`); the
`brand.fontFamily` stack already lists it first, so nothing else changes.

## Decisions made where the brief was open

- **Screenshot numbering.** The actual pixel content of `devin-web-10…19` is
  offset from `assets.md` (e.g. the Starcup "Ready to merge" PR is
  `devin-web-12.png`, not `-13`). Media was chosen by opening the files.
- **Concurrency.** The recordings show sequential stages, so the bays are used
  as stage summaries; no concurrent playback is faked.
- **Simulator footage.** `androidios.mp4` also contains an Android emulator;
  the default crop isolates the iPhone Simulator so the Mac-launch claim stays
  accurate.
- **Holds.** The PR result is held for 5s and every caption for ≥ 4s.
- **Speed badge.** `content.speedBadge` (`3x`) is a prop but is off in every
  default scene; the approved "3x" claim is expressed only in text if enabled.
- **`consoleLine`** is an extra brand token for hairlines on the dark console.
