---
name: motion-native-e2e
description: Run and record the native macOS Motion SIGNAL demonstration with a live source-and-results sidecar, genuine AX/Quartz input, and saved/exported artifact checks.
---

# Native Motion testing

Use `creative-suite/demos/motion/README.md` and `TEST_PLAN.md` as the tested
workflow. This harness targets an unlocked 1600×1200 macOS desktop, not a
browser. The static artwork is disclosed; GUI actions create the animation.

## Devin Secrets Needed

None. Accessibility and Screen Recording permissions are local OS grants.

## Important setup details

- Package into a new persistent `DEVIN_DIST` directory. Never rebuild over a
  running app. Stop the passive sidecar before recompiling its executable.
- Compile `NativeInput.swift` and `ScriptViewer.swift` with `swiftc`; no
  third-party Swift packages or Python Quartz module are needed.
- Wait for the native project window before arranging it. A launch may create
  an unused default sample window; close only that known sample.
- A newly opened project resets splitters and panel expansion. Restore the
  documented layout and confirm the static seed before running the driver.
- Use fresh output paths to avoid unhandled replacement prompts.

## Native input pitfalls

- AX supplies coordinates and observable control values; Quartz supplies real
  clicks, held drags and keys. Do not import the app model to perform edits.
- Text selection can be unreliable with Cmd-A in custom native menu contexts.
  Triple-click selection is used for this harness's single-line inputs.
- Finish numeric editing at the current playhead before seeking or hiding a
  channel row. A still-focused field may re-commit at the new time.
- Do not click the window resize border to seek to duration. Begin a held drag
  inside the ruler, move beyond its endpoint, and verify the exact timecode.
- For native Save As, wait for `saveAsNameTextField`; after Cmd-Shift-G wait
  for `PathTextField`. Enter the parent folder and filename separately.

## Evidence

- The sidecar must show actual source/current line and only observed results.
- Record continuously with the pointer visible, and annotate meaningful
  assertions. Capture a screenshot while the scrub mouse button is held.
- Inspect saved JSON read-only and decode the whole rendered movie. Metadata
  alone does not prove varying frames or successful complete decoding.
- Inspect output duration: automatic recording cuts may be much shorter than
  the real run. Retain raw segments and create a natural-speed continuous MP4
  when required. Normalize segment-boundary timestamps rather than speeding
  through edits. Inspect full-size frames for legibility and panel visibility.
- Leave the real Motion app running visibly with final playback.
- Report UI/harness workarounds and untested scope; do not claim Adobe parity.
