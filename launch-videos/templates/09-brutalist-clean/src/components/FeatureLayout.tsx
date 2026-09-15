import React from "react";
import { AbsoluteFill } from "remotion";
import { HEIGHT, space, TICKER_HEIGHT, WIDTH } from "../theme";
import { Masthead } from "./Masthead";
import { Headline } from "./Headline";

export const FEATURE_HEADLINE_SIZE = 64;
export const FEATURE_HEADLINE_TOP = 148;
export const FRAME_TOP = FEATURE_HEADLINE_TOP + FEATURE_HEADLINE_SIZE * 2 + 40;
export const FRAME_W = WIDTH - space.margin * 2;
export const FRAME_H = HEIGHT - TICKER_HEIGHT - 40 - FRAME_TOP;

type Props = {
  index: string;
  kicker: string;
  lines: string[];
  children: React.ReactNode;
};

/**
 * Shared layout for the "product in action" scenes: masthead, two-line
 * headline, then a full-width thick-framed screenshot.
 */
export const FeatureLayout: React.FC<Props> = ({ index, kicker, lines, children }) => (
  <AbsoluteFill>
    <Masthead left={kicker} right={index} />
    <div style={{ position: "absolute", left: space.margin, top: FEATURE_HEADLINE_TOP }}>
      <Headline lines={lines} size={FEATURE_HEADLINE_SIZE} stagger={5} />
    </div>
    <div style={{ position: "absolute", left: space.margin, top: FRAME_TOP }}>{children}</div>
  </AbsoluteFill>
);
