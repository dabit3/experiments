# Devin launch video templates — shared brief

Twenty product-launch video templates for an AI coding / AI agent product (Devin). Each template lives in
`launch-videos/templates/NN-slug/` as a standalone [Remotion](https://www.remotion.dev) project and renders a
1920x1080, 30fps MP4 of roughly 35–50 seconds. All templates share the assets and tokens in `launch-videos/assets/`.

## Launch used for the test video: Devin on macOS / native iOS

Use this content for every template's copy. Text on screen narrates what is happening: short, declarative lines,
one idea at a time. Do not paraphrase into marketing fluff; keep it concrete.

- **What it is.** Devin can now run in a Mac VM. It writes and tests code for Mac and iOS apps.
- **Problem / context.** Before, iOS teams either QA'd the app by hand or waited 20+ minutes for CI to say whether it
  worked. No coding agent could build, run and tap through an iPhone app on its own.
- **Product in action (pick 3–4 feature moments).**
  1. Devin builds and runs the app in Xcode / the iOS Simulator inside the session.
  2. A live iPhone Simulator tab in the session: Devin taps, types, scrolls and navigates like a person — you can watch and tap too.
  3. Devin reproduces a bug in the Simulator, fixes it, re-runs the UI tests and opens a PR.
  4. Devin checks screens across iPhone/iPad sizes, dark mode and orientations; records screenshots/video and compares them pixel for pixel.
  5. (Optional) Upgrades dependencies or Swift versions and confirms the app still builds and runs.
  6. (Optional) React Native / Flutter / Expo toolchains, deep links, permission dialogs, localization, local push notifications.
- **Outcome / metrics.**
  - "Minutes, not 20+ minute CI round-trips."
  - "The only coding agent with a Mac cloud agent." (Competitors are Linux-only or run Mac/iOS apps locally.)
  - "Same security as Linux and Windows VMs."
  - "No price increase — same as Linux cloud sessions."
  - "macOS child sessions, Declarative Repo Setup, Devin API and automations all work on Mac."
- **End card.** Devin lockup (`assets/brand/`) + one line, e.g. "Devin now runs on Mac." / "Build, run and test iOS apps in the cloud." / "devin.ai".

Use case lines you may quote verbatim: "Building and testing a new feature end-to-end", "Reproducing and fixing a bug
in the iOS Simulator", "QAing an app before shipping", "Checking screens across iPhone/iPad sizes, dark mode and
orientations", "Upgrading dependencies or Swift versions and confirming the app still builds and runs".

## Required structure (every template)

1. **Hook** — one line, 2–4 s.
2. **Problem or context** — 1–2 lines, 4–6 s.
3. **Product in action** — 3–4 feature moments, 5–8 s each, each with on-screen narration.
4. **Outcome / metrics** — 4–6 s.
5. **Logo end card** — 3–4 s.

## Craft rules (every template)

- Easing: ease-out for entrances, ease-in-out for moves, ease-in for exits. Use the bezier curves in `tokens.json`.
- No more than two motion types per scene (e.g. fade + scale, or slide + fade — not fade + scale + slide + blur).
- Generous negative space. Nothing on screen that isn't doing work. No decorative particles, no stock icons.
- Text: short, declarative, one idea at a time. Never more than ~8 words per line, never more than two lines at once
  (except where the direction explicitly calls for a list or grid).
- Use the type, color, spacing, radius and shadow tokens from `assets/tokens.json`. Fonts: Inter (load via
  `@remotion/google-fonts/Inter`) and JetBrains Mono (`@remotion/google-fonts/JetBrainsMono`) unless the direction
  specifies a serif/other face — then use a Google Font that matches the direction.
- Consistent light source, consistent corner radius, consistent frame margins (120px at 1080p).
- Output must feel finished: no placeholder text, no misaligned elements, no clipped text.

## Assets

- `assets/brand/devin-lockup-horizontal-black.png` — horizontal "Devin" lockup, black, transparent background (for light backgrounds).
- `assets/brand/devin-lockup-horizontal-white.png` — same lockup in white (for dark backgrounds).
- `assets/brand/devin-mark-black.png`, `assets/brand/devin-mark-white.png` — square logo mark only.
- `assets/screens/` — 31 real product screenshots (see `assets/screens/MANIFEST.md`). Screen *recordings* were not
  provided: simulate motion by animating over the screenshots (Ken Burns push-ins, panning, cursor overlays, typed
  text overlays, cross-fading between sequential screenshots such as web-3 → web-4 → web-5). Do not invent a UI that
  contradicts the screenshots; you may crop, mask, and re-compose them.
- `assets/tokens.json` — design tokens.

Remotion cannot load files outside its public directory, so point each template at the shared assets:
`Config.setPublicDir("../../assets")` in `remotion.config.ts`, and reference files with `staticFile("screens/devin-web-1.png")`.
Do **not** copy the screenshots into the template directory.
