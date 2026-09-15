import React from "react";
import { AbsoluteFill } from "remotion";
import { color, space } from "../tokens";

export const MARGIN = space.frameMargin1080p;

/** Screen stage: 1520 wide at the screenshot aspect, centred horizontally. */
export const STAGE_W = 1520;
export const STAGE_H = Math.round(STAGE_W / (1000 / 543));
export const STAGE_X = (1920 - STAGE_W) / 2;
export const STAGE_Y = 116;
export const LABEL_Y = 56;
export const CAPTION_Y = STAGE_Y + STAGE_H + 40;

/** Type scale for this template (larger than the site scale; 1080p px). */
export const SIZE = {
  hero: 136,
  headline: 72,
  caption: 48,
  body: 40,
  label: 24,
} as const;

export const Paper: React.FC<{ children: React.ReactNode }> = ({ children }) => (
  <AbsoluteFill style={{ background: color.paper }}>{children}</AbsoluteFill>
);
