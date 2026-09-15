# 05 — Kinetic Typography Title Sequence

Typography is the transition mechanism. Every demonstration beat opens with one
complete caption phrase standing inside a hairline plate whose geometry already
matches the footage that follows. The phrase then moves to the margin and scales
down into a quiet caption while the real product footage rises into the plate it
vacated. Phrases move as whole graphic objects — no per-letter animation, no
tracking changes, no springs.

Remotion 4 · React 18 · TypeScript · Zod · 1920×1080 · 30 fps · no audio.

```sh
npm install            # if the headless browser fails: npx remotion browser ensure
npm run dev            # Remotion Studio
npm run typecheck && npm run lint
npm run render         # out/launch.mp4  (45 s with default props)
npm run still          # out/poster.png  (frame 690, beat 03)
```

Footage is read from `../../assets` via `Config.setPublicDir("../../assets")` and
`staticFile()`. Nothing is copied into this directory.

## Scene table (default "Devin on Mac" props, 1350 frames)

| # | Scene | Frames | Time | Layout | Media | Text |
|---|-------|--------|------|--------|-------|------|
| 0 | `title` | 0–119 | 0.0–4.0 s | centered | — | eyebrow `New`, headline with accent `Mac VM`, subhead |
| 1 | `pick` | 120–299 | 4.0–10.0 s | `top` | `pick` — `devin-web-4.png` cropped to prompt box + OS picker | caption 0 |
| 2 | `build` | 300–539 | 10.0–18.0 s | `left` | `work` → `verify` — session with iPhone recording + PR, then testing player with checklist | caption 1 |
| 3 | `taps` | 540–749 | 18.0–25.0 s | `right` | `simulator` — `androidios.mp4` cropped to the iPhone Simulator, 1× | caption 2 |
| 4 | `sizes` | 750–989 | 25.0–33.0 s | `bottom` | `sizes` → `ipad` — six-phone PR comment (dark mode), then iPad Pro acceptance run | caption 5 |
| 5 | `ship` | 990–1169 | 33.0–39.0 s | `left` | `result` — session with demo recording beside the open PR | caption 6 |
| 6 | `end` | 1170–1349 | 39.0–45.0 s | centered | logo | outro line, feature-name lockup, CTA label + URL |

Inside a beat (defaults in `timing`):

| Phase | Frames | What happens |
|-------|--------|--------------|
| enter | 0–16 | hairline plate fades in, phrase rises into it |
| hold | 16–50 | phrase stands alone (`phraseHoldFrames`) |
| morph | 50–72 | phrase moves to the margin and scales to caption size (`morphFrames`), ease-in-out |
| media | 63– | footage rises into the plate (`mediaInFrames`), 1× playback |
| dissolve | split evenly | additional media slots crossfade (`dissolveFrames`) |
| exit | last 10 | everything eases out upward (`exitFrames`) |

The caption is on screen from frame 0 of the beat to its end, so every caption holds
far longer than the 2.5 s minimum; footage occupies ~75 % of each beat.

## Editable props

All props are validated by `launchPropsSchema` (`src/schema.ts`) and editable in
Remotion Studio.

- **`brand`** — all Devin color tokens (`paper`, `surface`, `line`, `ink`, `inkMuted`,
  `inkSubtle`, `accent`, `black`, `blackRaised`, `white`), `fontFamily`,
  `monoFontFamily`, `logoLight`, `logoDark`.
- **`content`** — `featureName`, `eyebrow`, `headline`, `accentWord` (substring of the
  headline set in the accent color), `subhead`, `captions[]`, `useCases[]`,
  `stages[]`, `cta {label,url}`, `outroLine`, `speedBadge`.
- **`media`** — named slots. Each has `src` (relative to `launch-videos/assets`),
  `kind` (`image`/`video`), `naturalWidth`/`naturalHeight`, optional fractional `crop`
  `{x,y,w,h}`, `startFrom`, `playbackRate`, and `align` (`top`/`center`/`bottom`, which
  edge to keep when cover-fitting). Media is only ever cropped and scaled.
- **`scenes`** — ordered list. `title`, `beat`, and `end` scenes each carry
  `durationInFrames`; the composition length is their sum (`calculateMetadata`).
  A `beat` also has `captionIndex`, `media[]` (slot names shown in sequence),
  `layout` (`top` / `bottom` / `left` / `right` — where the caption settles) and an
  optional mono `index` label.
- **`timing`** — `phraseHoldFrames`, `morphFrames`, `mediaInFrames`,
  `dissolveFrames`, `exitFrames`.
- **`typography`** — `phraseSize`, `captionSize`, `displaySize`, `margin`,
  `frameRadius`.

Text lengths: `fitPhrase` (`src/layout.ts`) estimates the line count of a caption and
shrinks the standing phrase until it fits inside the plate, then derives the caption
size so the wrapped lines stay identical while the phrase moves. Long captions wrap
to up to five lines in tall plates and three in wide ones.

## Components

| File | Role |
|------|------|
| `src/scenes/TitleCard.tsx` | opening statement — eyebrow, headline with accent word, subhead |
| `src/scenes/Beat.tsx` | one demonstration beat: plate → phrase → caption → footage → exit |
| `src/scenes/EndCard.tsx` | outcome line, then feature-name lockup with logo, CTA, URL |
| `src/components/Phrase.tsx` | a phrase as a single graphic object (translate + scale between two poses) |
| `src/components/Demo.tsx` | `Frame` (hairline plate) and `Demo` (cropped `Img`/`OffthreadVideo` with optional speed badge) |
| `src/components/Label.tsx` | small mono labels (eyebrow, beat index) |
| `src/layout.ts` | plate geometry per layout, phrase fitting |
| `src/motion.ts` | ease-out-cubic entrances, ease-in-out moves, no overshoot |

## Swapping launches

1. Copy `defaultProps` from `src/defaults.ts` into a JSON file (or edit in Studio).
2. Replace `content` with the new launch copy; captions become beat phrases in order.
3. Point `media` slots at new files under `launch-videos/assets`, set their real
   `naturalWidth`/`naturalHeight`, and add a `crop` when only part of a shot matters.
4. Rebuild `scenes`: one `beat` per demonstration with a `captionIndex`, its media
   slots, and a `layout` chosen to match the footage aspect (`left`/`right` for tall
   crops, `top`/`bottom` for wide ones). Adjust `durationInFrames`; the composition
   length follows automatically.
5. `npx remotion render Launch out/launch.mp4 --props=./my-launch.json`.

## Decisions on ambiguous points

- The direction's "word establishes a frame" is implemented as a hairline plate
  (`surface` fill, `line` border) sized to the next media's aspect; the plate never
  transforms into the UI — footage simply fades in over it.
- The speed badge only renders when a video slot's `playbackRate` exceeds 1; the
  default film plays every recording at 1×, so no badge appears.
- Captions 3 and 4 from the launch copy are not used in the 45 s cut (beats use
  captions 0, 1, 2, 5, 6) to leave each demonstration on screen for 6–8 s.
- The phone recording is cropped to the iPhone Simulator half of `androidios.mp4`;
  the Android emulator is outside this launch's claims.
- NB International Pro is not shipped. If `assets/fonts/NBInternationalPro-{Regular,Medium}.woff2`
  are added, `src/fonts.ts` registers them and the default `fontFamily` stack picks
  them up; otherwise Inter (from `@remotion/google-fonts`) renders.
- ESLint is pinned to 9.x because `@remotion/eslint-config-flat` 4.0.521 does not load
  under ESLint 10.
