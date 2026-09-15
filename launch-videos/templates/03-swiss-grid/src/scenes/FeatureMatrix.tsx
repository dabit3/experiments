import React from "react";
import { interpolate, useCurrentFrame, useVideoConfig } from "remotion";
import { Figure } from "../components/Figure";
import { easeInOut, progress } from "../theme";
import { Feature, FIGURE_COL, FIGURE_SPAN, FIGURE_TOP, WEB_ASPECT } from "./Feature";

const BEAT = 96;

/** 06 — device matrix, dark mode, iPad. Motion: vertical pan over the screenshot grid + cross-fade to iPad. */
export const FeatureMatrix: React.FC<{ number: string }> = ({ number }) => {
  const frame = useCurrentFrame();
  const { durationInFrames } = useVideoConfig();

  const originY = interpolate(frame, [0, durationInFrames], [0.28, 0.72], { easing: easeInOut });
  const ipad = progress(frame, BEAT + 10, 24);

  return (
    <Feature
      number={number}
      beats={[
        { text: "Checks every screen on iPhone and iPad, in dark mode and both orientations.", enterAt: 6, exitAt: BEAT - 10 },
        { text: "Compares screenshots pixel for pixel.", enterAt: BEAT + 6 },
      ]}
    >
      <Figure
        col={FIGURE_COL}
        span={FIGURE_SPAN}
        top={FIGURE_TOP}
        aspect={WEB_ASPECT}
        scale={1.18}
        originX={0.5}
        originY={originY}
        layers={[{ src: "screens/devin-web-17.png" }, { src: "screens/devin-web-19.png", opacity: ipad }]}
      />
    </Feature>
  );
};
