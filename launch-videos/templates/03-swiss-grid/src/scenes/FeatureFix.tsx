import React from "react";
import { interpolate, useCurrentFrame } from "remotion";
import { Figure } from "../components/Figure";
import { easeInOut, progress } from "../theme";
import { Feature, FIGURE_COL, FIGURE_SPAN, FIGURE_TOP, WEB_ASPECT } from "./Feature";

const BEAT = 102;
const PULL_BACK = 96;

/** 05 — reproduce, fix, re-test, open a PR. Motion: push in on the Simulator, then pull back to reveal the PR. */
export const FeatureFix: React.FC<{ number: string }> = ({ number }) => {
  const frame = useCurrentFrame();

  const pushIn = interpolate(frame, [0, BEAT], [1, 1.12], { easing: easeInOut, extrapolateRight: "clamp" });
  const pullBack = interpolate(frame, [BEAT, BEAT + PULL_BACK], [1.12, 1], {
    easing: easeInOut,
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  const scale = frame < BEAT ? pushIn : pullBack;
  const session = progress(frame, BEAT - 6, 18);

  return (
    <Feature
      number={number}
      beats={[
        { text: "Devin reproduces the bug in the Simulator and fixes it.", enterAt: 6, exitAt: BEAT - 10 },
        { text: "Re-runs the UI tests. Opens a PR.", enterAt: BEAT + 6 },
      ]}
    >
      <Figure
        col={FIGURE_COL}
        span={FIGURE_SPAN}
        top={FIGURE_TOP}
        aspect={WEB_ASPECT}
        scale={scale}
        originX={0.4}
        originY={0.5}
        layers={[{ src: "screens/devin-web-14.png" }, { src: "screens/devin-web-9.png", opacity: session }]}
      />
    </Feature>
  );
};
