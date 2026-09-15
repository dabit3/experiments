import React from "react";
import { AbsoluteFill, useCurrentFrame } from "remotion";
import { color } from "../tokens";
import { parallax } from "../lib/motion";

/**
 * Soft, dark, out-of-focus gradient. Two large light pools: the key light top-left (cool white),
 * a faint accent bloom lower-right. Drifts very slowly with the deepest parallax layer.
 */
export const Background: React.FC = () => {
  const frame = useCurrentFrame();
  const p = parallax(frame, 0);
  return (
    <AbsoluteFill style={{ backgroundColor: color.darkBg, overflow: "hidden" }}>
      <div
        style={{
          position: "absolute",
          inset: -200,
          transform: `translate(${p.x}px, ${p.y}px)`,
          background: [
            `radial-gradient(1200px 900px at 10% 2%, rgba(255,255,255,0.26), rgba(255,255,255,0) 70%)`,
            `radial-gradient(1400px 1000px at 94% 98%, rgba(34,0,255,0.30), rgba(34,0,255,0) 70%)`,
            `radial-gradient(1000px 800px at 62% 42%, rgba(120,110,255,0.06), rgba(120,110,255,0) 70%)`,
            `linear-gradient(160deg, #1A1918 0%, ${color.darkBg} 55%, #0C0B10 100%)`,
          ].join(","),
        }}
      />
    </AbsoluteFill>
  );
};
