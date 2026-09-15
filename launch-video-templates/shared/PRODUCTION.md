# Production contract

Each design owns exactly `templates/<NN-slug>/`. Do not edit the shared toolchain,
source assets, or another design. Add only your template directory to your branch.
The coordinator integrates all twenty directories.

## Required files

- `index.tsx`: Remotion `registerRoot` with a composition ID `Launch`.
- `template.json`: metadata with `id`, `title`, `compositionId: "Launch"`,
  `width: 1920`, `height: 1080`, `fps: 30`, `durationSeconds` (28–50).
- `README.md`: editable copy/timing locations, render commands, source-media
  choices, design notes and known limits. Include a scene table with timestamps,
  copy, media, and the at-most-two motion families used per scene.
- Additional TSX/JSON/CSS/helper files within your directory as needed.

## Deliverables

1. A polished, complete H.264 MP4, 1920×1080 at 30 fps.
2. A full-frame 1920×1080 poster PNG from the finished render.
3. A contact sheet showing hook, context, every feature, outcome and end card.
4. Editable, committed source, pushed to your own additive branch.

Keep rendered outputs outside git (`out/` is ignored). Upload the MP4, poster,
and contact sheet with `upload_attachment` and return their URLs. Do not open an
individual PR; the collection receives one integration PR. Do not deploy publicly.

## Story

Tell the launch of **Devin on macOS and iOS**:

- Hook: the coding agent can now work on your Mac and iPhone apps.
- Context: iOS teams manually QA or wait 20+ minutes for CI feedback.
- Four distinct feature beats: build/run in a managed Mac VM; interact with an
  app in iOS Simulator; reproduce/fix/retest a bug; review visible test evidence.
- Outcome: a working app you can inspect in the session. Same price as Linux VMs.
- End card: supplied Devin logo, macOS + iOS, short CTA (e.g. "Build. Run. See it.").

Copy may be adapted for the design. Keep one clear, short, declarative headline
at a time and generous negative space. Motion should support the current action,
not add decorative noise. Entrances use ease-out; moves use ease-in-out;
hard cuts/linear typing are allowed when the chosen direction requires them.
At most TWO concurrent motion families per scene.

Allowed: build/run/unit/UI tests via Xcode, tapping/typing/scrolling, live iPhone
Simulator within the session, one interactive device at a time, iPhone/iPad sizes,
dark mode/orientation, dependency and Swift upgrades, recordings/screenshots,
managed/security-provided Mac capacity, Mac child sessions, API/automation support.
Same price as Linux. No claim of guaranteed speed or cost reduction.

Do not imply real-device support, app signing/Store/TestFlight distribution,
remote APNs notifications, Apple IDs/iCloud, Bluetooth, camera/AR, or guaranteed
support for every Apple platform. Don't imply same-frame side-by-side devices
are simultaneously interactively controlled. Metrics must use supplied facts:
"20+ min" CI context; "0" price increase; "4" workflow steps. No invented numbers.
An accelerated timeline must visibly say "Illustrative timeline" or use scene
progress instead of purported elapsed execution time.

## Source media

Inspect source PNGs and sampled MP4 frames before selecting crops. Preserve aspect
ratio. Show iOS UI prominently; don't deliver a generic coding-agent slideshow.

- `devin-web-10/11.png`: native Wisp iPhone Simulator checks. These show failed as
  well as passed results. Never caption them as all passing.
- `devin-web-12.png`: agent session with native iPhone app and PR panel.
- `devin-web-13.png`: macOS session and feature request.
- `devin-web-14.png`: native app screenshot (inspect before crop).
- `devin-web-18.png`: iPhone Simulator with visible review evidence.
- Other supplied web/desktop/CLI screenshots may support context.
- `devin-testing-2.mp4`: generic web-app QA recording, **NOT native iOS**.
- `model-selector-local.mp4`: desktop model selector, **NOT Mac VM selection**.

Live clips must be used in a truthful generic testing or desktop moment. For
native moments, adapt supplied screenshots into motion mockups or create a clean
representative Devin+iPhone layout with the real screenshot contents. Do not
claim you captured new iOS footage. Document representative/mockup regions and
use a quiet "Illustrative workflow" label where staged activity could be
mistaken for a real test run. Do not fabricate screenshot test pass outcomes.

The original source files are in `public/assets`. Use `staticFile(...)`, `Img`,
and Remotion `OffthreadVideo` (muted) rather than network URLs, base64 data, HTML
video tags, or externally hosted fonts. Keep output deterministic via frame-based
animation; no CSS runtime animations, `Math.random()`, or `Date.now()`.

The source clips contain incidental audio. Mute them. Sound is optional except
Kinetic Type, which should include a simple original beat track with no external
copyrighted music. Keynote Minimal should have silent feature holds. Document
audio choices in each README.

## Brand and typography

Figma design context was retrieved from the corrected file:
https://www.figma.com/design/evS5ExlrnLrUCMPm395OHw/Devin?node-id=0-1

Use `shared/brand.ts` and root README for inspected tokens/measurements. This is
design-reference adaptation, not a pixel-copy of the website. Screenshots and
logo assets are authoritative. Don't redraw the logo or show both black and white
variants together.

NB International Pro / Inter names were observed; licensed font binaries weren't
provided. System fallbacks are explicit. If bundling an open font, keep its
license, pin the dependency to a version published ≥7 days ago, avoid changing
shared package files, and document the substitution. Typography can vary where
the direction specifically calls for serif, monospace, or geometric display.

## Verification

Run `npm ci`, `npm run lint`, `npm run typecheck`, `npm run validate`.
Render with `npm run render -- <slug>`. Remotion may download its headless browser;
this is offline video rendering, not app/browser UI testing. No testing-agent
handoff is needed for render checks. Inspect complete-scene frames and transitions
using rendered stills or ffmpeg extraction. Fix clipping, accidental blank frames,
unreadable copy, missing assets, and aspect-ratio distortion before completion.
Use ffprobe to verify frame rate, codec, dimensions and duration.

Read Remotion help/source for exact options if needed. Default concurrency=2 keeps
rendering reasonable on Mac VMs; do not kill the desktop browser. Rendering a
headless Remotion browser is separate from driving the user's app.
