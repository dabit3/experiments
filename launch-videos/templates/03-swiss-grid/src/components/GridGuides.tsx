import React from "react";
import { AbsoluteFill, useCurrentFrame } from "remotion";
import { GUIDE_FRAMES, SCENES, TOTAL_FRAMES } from "../scenes";
import { color, easeInOut, grid, progress } from "../theme";

const boundaries = (() => {
  const out: number[] = [];
  let acc = 0;
  for (const scene of SCENES) {
    acc += scene.durationInFrames;
    if (acc < TOTAL_FRAMES) out.push(acc);
  }
  return out;
})();

/** Faint 12-column guides that surface around every scene boundary. */
export const GridGuides: React.FC = () => {
  const frame = useCurrentFrame();

  let visibility = 0;
  for (const b of boundaries) {
    const d = Math.abs(frame - b);
    if (d < GUIDE_FRAMES) {
      visibility = Math.max(visibility, 1 - progress(d, 0, GUIDE_FRAMES, easeInOut));
    }
  }
  // Guides also frame the very first second.
  visibility = Math.max(visibility, 1 - progress(frame, GUIDE_FRAMES * 0.6, GUIDE_FRAMES, easeInOut));

  if (visibility <= 0) return null;

  const line = color.gray300;

  return (
    <AbsoluteFill style={{ opacity: visibility, pointerEvents: "none" }}>
      {Array.from({ length: grid.columns }).map((_, i) => (
        <React.Fragment key={i}>
          <div
            style={{
              position: "absolute",
              left: grid.x(i),
              top: 0,
              width: 1,
              height: "100%",
              background: line,
            }}
          />
          <div
            style={{
              position: "absolute",
              left: grid.x(i) + grid.column - 1,
              top: 0,
              width: 1,
              height: "100%",
              background: line,
            }}
          />
        </React.Fragment>
      ))}
      {[grid.rowTop, grid.rowMid, grid.rowBottom].map((y) => (
        <div
          key={y}
          style={{
            position: "absolute",
            left: 0,
            top: y,
            width: "100%",
            height: 1,
            background: line,
          }}
        />
      ))}
    </AbsoluteFill>
  );
};
