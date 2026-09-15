# 06 — Kinetic Type

40 seconds · 1920 × 1080 · 30 fps · H.264. A percussive, type-led launch film:
black, paper and pale mint; oversized type; hard cuts; short native UI inserts.
The first frame carries the hook, and the last holds the supplied Devin logo.

## Edit and render

From `launch-video-templates`:

```sh
npm ci
npm run lint
npm run typecheck
npm run validate
npm run render -- 06-kinetic-type
```

`config.ts` is the copy and timing interface. Each scene has a headline, note,
eyebrow, theme, font size and beat count. At 120 BPM each beat is 15 frames.
The scene list must total 80 beats / 1,200 frames. If changing total length,
update `template.json` and `DURATION` in the beat generator too.
`index.tsx` owns layouts, source crops, typography entrance curves and colors.
Screenshot crop coordinates use a 1,568-pixel reference width; images retain
their natural aspect ratio. All source assets are local.

The committed `original-beat.wav` is ready to render without Python. To recreate
it exactly, run `python3 templates/06-kinetic-type/generate_beat.py` from the
project root. It uses only Python's standard library, oscillators and seeded
noise: original kick, snare, hats, bass and three-note percussion; no samples,
copyrighted music, external libraries or voice synthesis. The 48 kHz mono track
peaks at −2.16 dBFS before Remotion's 0.8 volume. The end card has a short
two-note release and a quiet hold. The source video's incidental audio is muted.

## Scene timing and motion budget

All transitions are cuts. UI inserts last **2.5 seconds** each. The word
entrances use an eight-frame cubic ease-out; slam scale and row translations
are one coordinated typography transform family. There are no opacity
crossfades, runtime CSS animations, random animation values or camera drift.
The bottom chapter rail changes only at a cut. No scene exceeds two motion
families; most use one.

| Time | Copy / purpose | Media | Concurrent motion families |
| --- | --- | --- | --- |
| 0–2.5 | Your next app. / hook | None | Type scale/translation |
| 2.5–5 | Meet Devin. / macOS + iOS | Native maze iPhone crop | Type translation; screenshot static |
| 5–7 | Manual QA. / before | None | Split row translation |
| 7–9 | 20+ min. / prior CI wait | None | Type scale/translation |
| 9–11.5 | Build. Run. / feature 01 | None | Split row translation |
| 11.5–14 | An app. Running. | Native maze iPhone crop | Type translation; screenshot static |
| 14–16 | Tap. Type. Scroll. / feature 02 | None | Split row translation |
| 16–18.5 | Right there. | Native Wisp iPhone crop | Type translation; screenshot static |
| 18.5–20.5 | Reproduce. / feature 03 | None | Type translation |
| 20.5–21.5 | Fix. | None | Type scale/translation |
| 21.5–23 | Retest. | None | Type scale/translation |
| 23–25.5 | See the details. | Full Wisp checks, failures retained | Type translation; screenshot static |
| 25.5–27.5 | Review the evidence. / feature 04 | None | Split row translation |
| 27.5–30 | Watch it back. | Actual web QA video, 12–14.5s | Type translation + recorded source motion |
| 30–32.5 | A working app. / outcome | Rescue charts iPhone crop | Type translation; screenshot static |
| 32.5–35 | Live in your session. | None | Split row translation |
| 35–37.5 | Same price as Linux. | None | Type scale/translation |
| 37.5–40 | Devin / macOS + iOS / Build. Run. See it. | Supplied white logo | Logo scale entrance |

## Provenance and truthful representation

- `public/assets/devin-web-14.png`: user-supplied Afterhours Maze iPhone
  Simulator screenshot. Used for the intro and build/run inserts. Only the
  phone is isolated; its app contents are not fabricated.
- `public/assets/devin-web-10.png`: user-supplied Wisp Simulator checks.
  Phone crop supports the Simulator beat. The later full screenshot preserves
  **12 passed / 3 failed / 2 untested** and the visible failure details. It is
  not presented as an all-passing run or a newly repaired result.
- `public/assets/devin-web-18.png`: user-supplied Rescue charts iPhone
  Simulator screenshot. Phone-only crop supports the inspectable-app outcome.
  No screenshot result totals are generalized into launch performance claims.
- Native inserts use supplied stills, not newly captured iOS footage.
  Each phone insert visibly says “iPhone Simulator · Illustrative workflow.”
  The build/fix/retest titles describe the launch capability rather than
  pretending to document one continuous real execution.
- `public/assets/devin-testing-2.mp4`: actual supplied generic **web QA**
  recording, source seconds 12–14.5, used with muted `OffthreadVideo`. The whole
  source frame is fit without distortion. The on-screen caption explicitly
  reads “Supplied web QA recording · Not iOS footage.”
- `public/assets/logo-white.png`: supplied, unmodified Devin wordmark used
  against ink on the end card with its original aspect ratio.
- “20+ min” is the user's prior CI context, not a measurement of this film's
  workflow. Same pricing as Linux is the supplied launch claim. No promised
  speedup, shipping/signing support, real-device control or all-pass claim.

## Brand adaptation and limitations

The palette adapts the inspected Figma website tokens in `shared/brand.ts`:
`#fcfcfc`, `#d5f0e8`, with a slightly darker high-contrast `#111313` ink. This is
an original motion direction, not a pixel copy of the marketing site.
NB International Pro and Inter binaries were not provided. Display and utility
type use **Helvetica Neue → Helvetica → Arial → sans-serif**. The macOS render
uses the system Helvetica Neue; no remote fonts are fetched. Different hosts
may select a fallback and should recheck line widths.

The native screenshot inserts are intentionally brief punctuation between
readable type holds, not tutorials. Their small embedded text is contextual;
the film's headline, description and provenance labels carry the message.
The original audio is rhythmic instrumental only; narration is visual.

Rendered media and QA artifacts belong under the ignored `out/` directory.
No shared files, dependencies or other templates are modified.

## Offline media QA

On macOS, `swift templates/06-kinetic-type/contact_sheet.swift` generates a
labelled 28-frame contact sheet from the rendered MP4: every scene plus ten
key boundary frames, including the first and last frames. It also generates
two transition sheets covering the frames before, at and eight frames after
every cut. It uses system AppKit, Node 22+ type stripping and `ffmpeg` on PATH;
it adds no npm dependencies. The full-frame poster is extracted at 3.5 seconds:

```sh
ffmpeg -y -ss 3.5 -i out/06-kinetic-type.mp4 -frames:v 1 out/06-kinetic-type-poster.png
ffprobe -v error -show_streams -show_format out/06-kinetic-type.mp4
```
