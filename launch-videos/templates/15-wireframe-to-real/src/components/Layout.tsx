import React from "react";
import { AbsoluteFill } from "remotion";
import { color, space } from "../tokens";

export const MARGIN = space.frameMargin1080p;

/** Screen stage: 1240 wide at the screenshot aspect, centred horizontally. */
export const STAGE_W = 1240;
export const STAGE_H = Math.round(STAGE_W / (1000 / 543));
export const STAGE_X = (1920 - STAGE_W) / 2;
export const STAGE_Y = 156;
export const LABEL_Y = MARGIN;
export const CAPTION_Y = STAGE_Y + STAGE_H + 52;

export const Paper: React.FC<{ children: React.ReactNode }> = ({ children }) => (
  <AbsoluteFill style={{ background: color.paper }}>{children}</AbsoluteFill>
);
