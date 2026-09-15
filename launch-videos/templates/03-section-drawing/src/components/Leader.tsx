import React from "react";
import type { Brand } from "../schema";
import { HEIGHT, WIDTH } from "../layout";

/**
 * A short leader line from a caption to an exact point on the product UI: a horizontal
 * run out of the caption, one bend, then a straight segment ending in a small accent dot.
 */
export const Leader: React.FC<{
  brand: Brand;
  from: { x: number; y: number };
  to: { x: number; y: number };
  side: "left" | "right";
  progress: number;
}> = ({ brand, from, to, side, progress }) => {
  if (progress <= 0) {
    return null;
  }
  const dir = side === "right" ? -1 : 1;
  const run = 36;
  const bend = { x: from.x + dir * run, y: from.y };
  const seg1 = run;
  const seg2 = Math.hypot(to.x - bend.x, to.y - bend.y);
  const total = seg1 + seg2;
  const dash = total * progress;
  const dotOpacity = progress >= 1 ? 1 : 0;
  return (
    <svg style={{ position: "absolute", left: 0, top: 0 }} width={WIDTH} height={HEIGHT}>
      <polyline
        points={`${from.x},${from.y} ${bend.x},${bend.y} ${to.x},${to.y}`}
        fill="none"
        stroke={brand.ink}
        strokeWidth={1.25}
        strokeDasharray={`${dash} ${total}`}
      />
      <circle cx={to.x} cy={to.y} r={5} fill={brand.accent} opacity={dotOpacity} />
      <circle
        cx={to.x}
        cy={to.y}
        r={11}
        fill="none"
        stroke={brand.accent}
        strokeWidth={1}
        opacity={dotOpacity * 0.6}
      />
    </svg>
  );
};
