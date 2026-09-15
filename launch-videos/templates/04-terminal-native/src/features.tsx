import React from "react";
import { FeatureSpec } from "./scenes/Feature";
import { TapOverlay } from "./components/CursorOverlay";
import { CONTEXT_COMMAND } from "./scenes/Context";

/** The 3–4 "product in action" moments from BRIEF.md, as terminal commands. */
export const features: FeatureSpec[] = [
  {
    history: CONTEXT_COMMAND,
    command: 'devin new "Build and test Reel Horizon on iOS"',
    output: [
      { prefix: "✓", prefixTone: "ok", text: "macOS VM ready" },
      { prefix: "→", tone: "dim", text: "xcodebuild -scheme ReelHorizon" },
      { prefix: "✓", prefixTone: "ok", text: "App running in the iOS Simulator" },
    ],
    shots: ["devin-web-4", "devin-web-13"],
    label: "01 · build & run",
    caption: ["Devin builds and runs the app in Xcode", "and the iOS Simulator, inside the session."],
  },
  {
    history: 'devin new "Build and test Reel Horizon on iOS"',
    command: "devin simulator --attach",
    output: [
      { prefix: "✓", prefixTone: "ok", text: "Live iPhone Simulator tab" },
      { prefix: "→", tone: "dim", text: "tap · type · scroll · navigate" },
      { prefix: "✓", prefixTone: "ok", text: "You can watch and tap too" },
    ],
    shots: ["devin-web-10", "devin-web-11"],
    label: "02 · live simulator",
    caption: ["Devin taps, types and scrolls like a person.", "You can watch, and tap, too."],
    overlay: (
      <TapOverlay
        at={126}
        taps={[
          { x: 0.325, y: 0.705 },
          { x: 0.325, y: 0.79 },
          { x: 0.3, y: 0.44 },
        ]}
      />
    ),
  },
  {
    history: "devin simulator --attach",
    command: "devin test --ui",
    output: [
      { prefix: "✗", prefixTone: "err", text: "1 failed · It should stream replies" },
      { prefix: "→", tone: "dim", text: "Reproduced in the Simulator · fixed" },
      { prefix: "✓", prefixTone: "ok", text: "15 passed · PR #161 opened" },
    ],
    shots: ["devin-web-9"],
    label: "03 · fix & ship",
    caption: ["Reproduces the bug, fixes it, re-runs the UI tests.", "Then opens a PR."],
  },
  {
    history: "devin test --ui",
    command: "devin screens --devices iphone,ipad --dark",
    output: [
      { prefix: "✓", prefixTone: "ok", text: "iPhone 17 Pro · iPad Pro 13" },
      { prefix: "→", tone: "dim", text: "light · dark · portrait · landscape" },
      { prefix: "✓", prefixTone: "ok", text: "0 pixel diffs" },
    ],
    shots: ["devin-web-17", "devin-web-19"],
    label: "04 · every screen",
    caption: ["Checks iPhone and iPad sizes, dark mode", "and orientations. Compared pixel for pixel."],
  },
];
