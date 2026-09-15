import React from "react";
import { interpolate, useCurrentFrame } from "remotion";
import { bp, easeInOut, easeOut } from "../theme";

export type CursorStop = { x: number; y: number; at: number; click?: boolean };

/**
 * Animated pointer overlay. Moves between stops with ease-in-out; optional click ring at each stop.
 * Coordinates are in the parent's pixel space.
 */
export const Cursor: React.FC<{ stops: CursorStop[]; travel?: number; appearAt?: number; hideAt?: number }> = ({
  stops,
  travel = 20,
  appearAt,
  hideAt,
}) => {
  const frame = useCurrentFrame();
  const first = stops[0];
  const start = appearAt ?? first.at;
  if (frame < start) return null;
  if (hideAt !== undefined && frame > hideAt) return null;
  let x = first.x;
  let y = first.y;
  for (let i = 1; i < stops.length; i++) {
    const prev = stops[i - 1];
    const next = stops[i];
    const t = interpolate(frame, [next.at - travel, next.at], [0, 1], {
      extrapolateLeft: "clamp",
      extrapolateRight: "clamp",
      easing: easeInOut,
    });
    x = prev.x + (next.x - prev.x) * t;
    y = prev.y + (next.y - prev.y) * t;
    if (frame < next.at - travel) break;
  }
  const opacity = interpolate(frame, [start, start + 8], [0, 1], { extrapolateRight: "clamp", easing: easeOut });
  const ring = stops
    .filter((s) => s.click && frame >= s.at)
    .map((s) => {
      const p = interpolate(frame, [s.at, s.at + 14], [0, 1], { extrapolateRight: "clamp", easing: easeOut });
      if (p >= 1) return null;
      return (
        <circle key={s.at} cx={s.x} cy={s.y} r={6 + p * 22} fill="none" stroke={bp.lineBright} strokeWidth={1.5} opacity={1 - p} />
      );
    });
  return (
    <svg style={{ position: "absolute", inset: 0, width: "100%", height: "100%", overflow: "visible", opacity }}>
      {ring}
      <g transform={`translate(${x} ${y})`}>
        <path
          d="M0,0 L0,17 L4.2,13.3 L7.6,20.5 L10.4,19.2 L7,12.1 L12.6,12.1 Z"
          fill="#FFFFFF"
          stroke="#191919"
          strokeWidth={1.2}
          strokeLinejoin="round"
        />
      </g>
    </svg>
  );
};
