import React from "react";
import { Shot } from "../components/ScreenCard";
import { Line } from "../components/Narration";
import { Cursor, Tap, TypedPrompt } from "../components/Overlays";

export type FeatureContent = { shots: Shot[]; lines: Line[] };

/** 1. Start a macOS session → Devin builds and runs the app in the Simulator. */
export const featureSession: FeatureContent = {
  shots: [
    {
      src: "screens/devin-web-1.png",
      from: 0,
      scale: [1.04, 1.08],
      origin: "50% 45%",
      overlay: (
        <TypedPrompt
          at={{ x: 0.2265, y: 0.394 }}
          plateWidth={0.4}
          plateHeight={0.05}
          text="Build and test the iOS app in the Simulator"
          f0={22}
          f1={78}
          fontSize={16.5}
        />
      ),
    },
    {
      src: "screens/devin-web-4.png",
      from: 98,
      scale: [1.08, 1.12],
      origin: "30% 70%",
      overlay: <Cursor from={{ x: 0.262, y: 0.6 }} to={{ x: 0.278, y: 0.738 }} f0={104} f1={136} clickAt={142} />,
    },
    { src: "screens/devin-web-14.png", from: 168, scale: [1, 1.07], origin: "34% 48%" },
  ],
  lines: [
    { text: "Start a session on macOS.", from: 10, until: 156 },
    { text: "Devin builds and runs the app in the iOS Simulator.", from: 166 },
  ],
};

/** 2. Live iPhone Simulator tab — Devin taps, types and scrolls; you can too. */
export const featureSimulator: FeatureContent = {
  shots: [
    { src: "screens/devin-web-11.png", from: 0, scale: [1.02, 1.08], origin: "32% 50%" },
    {
      src: "screens/devin-web-10.png",
      from: 96,
      scale: [1, 1.07],
      origin: "32% 62%",
      overlay: <Tap at={{ x: 0.328, y: 0.795 }} f0={124} />,
    },
  ],
  lines: [
    { text: "A live iPhone Simulator, inside the session.", from: 10, until: 92 },
    { text: "Devin taps, types and scrolls — you can too.", from: 102 },
  ],
};

/** 3. Reproduce → fix → re-run UI tests → open a PR. */
export const featureBugfix: FeatureContent = {
  shots: [
    { src: "screens/devin-web-13.png", from: 0, scale: [1, 1.05], origin: "50% 90%", pan: { y: [0, -0.03] } },
    { src: "screens/devin-web-9.png", from: 104, scale: [1, 1.06], origin: "28% 42%" },
  ],
  lines: [
    { text: "Reproduces the bug. Fixes it. Re-runs the UI tests.", from: 10, until: 100 },
    { text: "Then opens the PR.", from: 110 },
  ],
};

/** 4. Device matrix — iPhone/iPad sizes, dark mode, orientations, pixel diffs. */
export const featureMatrix: FeatureContent = {
  shots: [
    { src: "screens/devin-web-17.png", from: 0, scale: [1.12, 1.2], origin: "40% 62%" },
    { src: "screens/devin-web-19.png", from: 112, scale: [1, 1.06], origin: "34% 50%" },
  ],
  lines: [
    { text: "Checks iPhone and iPad sizes, dark mode and orientations.", from: 10, until: 108 },
    { text: "Compares every screenshot pixel for pixel.", from: 118 },
  ],
};
