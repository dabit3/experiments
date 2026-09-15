import React from "react";
import { useCurrentFrame } from "remotion";
import { tokens } from "../tokens";
import type { Project } from "./MacroShot";

type Props = {
  x: number;
  y: number;
  project: Project;
  scale: number;
  /** Caret height in image px (matches the input's line height). */
  height?: number;
  period?: number;
};

/** Blinking text-input caret, positioned in image space. */
export const Caret: React.FC<Props> = ({ x, y, project, scale, height = 44, period = 32 }) => {
  const frame = useCurrentFrame();
  const on = frame % period < period / 2;
  const p = project(x, y);
  return (
    <div
      style={{
        position: "absolute",
        left: p.x,
        top: p.y - (height * scale) / 2,
        width: Math.max(2, 2 * scale * 0.6),
        height: height * scale,
        background: tokens.color.ink,
        opacity: on ? 1 : 0,
        borderRadius: 1,
      }}
    />
  );
};
