import React from "react";
import { Img, staticFile } from "remotion";
import type { Focus, Screen } from "../content";

type Props = {
  screen: Screen;
  width: number;
  height: number;
  zoom?: number; // multiplier on the cover scale (1 = exactly cover)
  focus?: Focus; // image point (0..1) kept at the centre of the box
  opacity?: number;
};

const clamp = (v: number, lo: number, hi: number) => Math.min(hi, Math.max(lo, v));

// Draws a screenshot at "cover" size inside a clipped box. Never distorts:
// scale is uniform, aspect ratio is preserved, edges are clamped.
export const Screenshot: React.FC<Props> = ({
  screen,
  width,
  height,
  zoom = 1,
  focus = { x: 0.5, y: 0.5 },
  opacity = 1,
}) => {
  const cover = Math.max(width / screen.w, height / screen.h) * zoom;
  const iw = screen.w * cover;
  const ih = screen.h * cover;
  const left = clamp(width / 2 - focus.x * iw, width - iw, 0);
  const top = clamp(height / 2 - focus.y * ih, height - ih, 0);
  return (
    <div style={{ position: "absolute", inset: 0, overflow: "hidden", opacity }}>
      <Img
        src={staticFile(screen.file)}
        style={{ position: "absolute", left, top, width: iw, height: ih, display: "block" }}
      />
    </div>
  );
};
