import React from "react";
import { interpolate, useCurrentFrame, useVideoConfig } from "remotion";
import { Figure } from "../components/Figure";
import { easeInOut, progress } from "../theme";
import { Feature, FIGURE_COL, FIGURE_SPAN, FIGURE_TOP, WEB_ASPECT } from "./Feature";

const BEAT = 96;

/** 04 — live iPhone Simulator. Motion: slow push-in on the phone + cross-fade (loading → app). */
export const FeatureWatch: React.FC<{ number: string }> = ({ number }) => {
  const frame = useCurrentFrame();
  const { durationInFrames } = useVideoConfig();

  const scale = interpolate(frame, [0, durationInFrames], [1, 1.14], { easing: easeInOut });
  const app = progress(frame, 36, 14);

  return (
    <Feature
      number={number}
      beats={[
        { text: "Watch Devin tap, type and scroll in a live iPhone Simulator.", enterAt: 6, exitAt: BEAT - 10 },
        { text: "You can tap too.", enterAt: BEAT + 6 },
      ]}
    >
      <Figure
        col={FIGURE_COL}
        span={FIGURE_SPAN}
        top={FIGURE_TOP}
        aspect={WEB_ASPECT}
        scale={scale}
        originX={0.18}
        originY={0.52}
        layers={[{ src: "screens/devin-web-11.png" }, { src: "screens/devin-web-10.png", opacity: app }]}
      />
    </Feature>
  );
};
