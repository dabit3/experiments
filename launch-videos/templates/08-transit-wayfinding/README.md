# 08 — Transit Wayfinding

A 45s, 1920x1080, 30fps Remotion 4 launch template that reads like a transit map: the demonstrated
workflow becomes one straight route with a few named stations. A restrained accent line is traced
from the origin to each station; at every station the real product recording expands out of the
route marker, holds as the dominant element (with a small route indicator top-right for context),
then collapses back. The map only returns briefly between demonstrations, and the route finishes at
the actual delivered outcome (the PR).

No audio. All footage is loaded from `launch-videos/assets/` via `staticFile()`
(`Config.setPublicDir("../../assets")`), shown flat and front-on with crop/scale only.

## Scripts

```sh
npm install
npm run dev        # Remotion Studio
npm run typecheck
npm run lint
npm run render     # -> out/launch.mp4 (video-only, Config.setMuted)
npm run still      # -> out/poster.png (frame 903, Verify station)
```

If the headless browser did not download during install: `npx remotion browser ensure`.

## Scenes (default props, 1350 frames)

| # | Scene id     | Type    | Frames    | Length | What you see                                                                                                  |
|---|--------------|---------|-----------|--------|---------------------------------------------------------------------------------------------------------------|
| 1 | `open`       | open    | 0–104     | 3.5s   | Headline + subhead, route revealed by a left-to-right wipe, accent line traced from the origin toward station 01. |
| 2 | `s1-request` | station | 105–284   | 6.0s   | **Request** — `screenshots/devin-web-5.png` (Virtual environment → macOS, checked) expands from the marker. Caption 1. |
| 3 | `l1`         | link    | 285–320   | 1.2s   | Back on the map: line runs Request → Build, arrival pulse.                                                    |
| 4 | `s2-build`   | station | 321–500   | 6.0s   | **Build** — `recordings/devin-working-4.mp4` (Devin working, Desktop tab). Caption 2.                          |
| 5 | `l2`         | link    | 501–536   | 1.2s   | Build → Run & test.                                                                                           |
| 6 | `s3-run`     | station | 537–776   | 8.0s   | **Run & test** — `recordings/androidios.mp4` cropped to the iPhone Simulator. Captions 3 and 4 (wipe between). |
| 7 | `l3`         | link    | 777–812   | 1.2s   | Run & test → Verify.                                                                                          |
| 8 | `s4-verify`  | station | 813–1007  | 6.5s   | **Verify** — `recordings/devin-testing-2.mp4` from 0:36 (pass list + summary). Caption 5.                      |
| 9 | `l4`         | link    | 1008–1043 | 1.2s   | Verify → PR.                                                                                                  |
| 10| `s5-pr`      | station | 1044–1214 | 5.7s   | **PR** — `screenshots/devin-web-12.png` ("Ready to merge", embedded Simulator demo). Caption 7.                |
| 11| `outro`      | outro   | 1215–1349 | 4.5s   | Completed route, `outro` line with accent word, CTA pill + URL.                                               |

Media never scales below its native pixel size more than the stage requires; a 1920px-wide recording
fills the 1472px stage (~77% of frame width).

## Editable props (`src/schema.ts`, defaults in `src/defaults.ts`)

- `content` — `feature`, `eyebrow`, `headline`, `headlineAccentWord` (single word coloured accent),
  `subhead`, `outro`, `outroAccentWord`, `ctaLabel`, `ctaUrl`, `speedBadge` (text only; it is
  rendered on a station's media only when that scene sets `speedBadge: true`).
- `brand` — `paper`, `surface`, `line`, `ink`, `inkMuted`, `inkSubtle`, `accent`, `white`,
  `fontFamily`, `monoFontFamily`, `logoLight`, `logoDark`, optional `licensedFontFiles`.
- `media` — a record of named slots. Each slot: `src` (relative to `assets/`), `kind`
  (`image` | `video`), `startFrom`, `playbackRate`, `crop` (fractions of the source), and the
  source dimensions so the frame is sized to the footage's real aspect ratio.
- `route` — `originLabel`, ordered `stations` (`id`, `name`, optional `branches`), `y`,
  `lineWidth`, `markerRadius`. Stations are spaced evenly across the safe area.
- `timing` — `arrive`, `expand`, `collapse`, `captionWipe` (frames).
- `scenes` — the ordered timeline. Each scene has `durationInFrames`; the composition length is
  their sum (`calculateMetadata`). Scene types: `open`, `station` (`station`, `media`,
  `captions[{ text, atFrame }]`), `link` (`from`, `to`), `outro`.

### Branches

Per the direction, branches only appear where they represent a supported choice. The default marks
the **Request** station with `Ubuntu / macOS / Windows` (the Hosted VM options visible in the
footage) with `macOS` as `chosen: true`. Remove `branches` from a station to draw a plain marker.
There is no support for branching the main line itself — the route is intentionally a single line.

## Swapping launches

1. Put footage under `launch-videos/assets/{screenshots,recordings}/`.
2. Copy `src/defaults.ts` and change copy, media slots (with real source dimensions), station names,
   and scene order/durations. Pass it with `--props=./my-launch.json`, or edit `defaults.ts` directly.
3. Keep captions to one line (~60 characters) at 30px; keep the total of `scenes[].durationInFrames`
   at the length you want (1350 for 45s).
4. `npm run render`.

Only claims from the launch copy file should be used in `captions` and `content`.

## Fonts

Inter (`@remotion/google-fonts/Inter`) is the fallback for NB International Pro; Geist Mono for mono.
`brand.fontFamily` and `brand.monoFontFamily` are plain CSS font stacks. If licensed NB International
Pro `.woff2` files are added to `assets/fonts/`, set
`brand.licensedFontFiles = { regular: "fonts/…-Regular.woff2", medium: "fonts/…-Medium.woff2" }`
and the template registers them via `@font-face`; otherwise nothing is requested and Inter renders.

## Decisions on ambiguous points

- Seven approved captions exist but only five stations; caption 6 ("Check iPhone and iPad sizes,
  dark mode, and orientations.") is omitted because no supplied footage shows it.
- `androidios.mp4` also shows an Android emulator; the default crop shows only the iPhone Simulator
  because Android is not part of the approved claims.
- The verify recording starts at 0:36 so the "6 passed / 0 failed" summary is visible for the whole
  hold.
- No default scene turns on the `3x` speed badge: no footage is sped up and the avoid-list rules
  out implied speed improvements. Set `speedBadge: true` on a station scene if you do speed footage
  up via `playbackRate`.
- Frame 0 is paper only (the open scene fades in over ~0.4s); use `npm run still` for thumbnails.
