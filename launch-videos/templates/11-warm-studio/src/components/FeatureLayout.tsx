import React from "react";
import { useCurrentFrame } from "remotion";
import { MARGIN, WIDTH, color } from "../tokens";
import { Label } from "./Text";
import { Narration, type Beat } from "./Narration";
import { fadeIn } from "./motion";
import { Scene } from "./Scene";

export const FIGURE_WIDTH = WIDTH - MARGIN * 2;
export const FIGURE_TOP = 400;

type FeatureLayoutProps = {
  label: string;
  beats: Beat[];
  children: React.ReactNode;
};

/**
 * Shared layout for the "product in action" scenes: a mono step label and a
 * two-line-max narration up top, and a wide product frame that bleeds off the
 * bottom edge so the screenshot reads as one continuous surface.
 */
export const FeatureLayout: React.FC<FeatureLayoutProps> = ({ label, beats, children }) => {
  const frame = useCurrentFrame();
  return (
    <Scene>
      <div style={{ position: "absolute", left: MARGIN, top: 120, opacity: fadeIn(frame) }}>
        <Label style={{ color: color.accent }}>{label}</Label>
      </div>
      <div style={{ position: "absolute", left: MARGIN, top: 172, right: MARGIN }}>
        <Narration beats={beats} size="h2" maxWidth={1680} />
      </div>
      <div
        style={{
          position: "absolute",
          left: MARGIN,
          top: FIGURE_TOP,
          opacity: fadeIn(frame, 6),
        }}
      >
        {children}
      </div>
    </Scene>
  );
};
