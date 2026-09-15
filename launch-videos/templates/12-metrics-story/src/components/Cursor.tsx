import React from "react";
import { useCurrentFrame } from "remotion";
import { easeInOut, easeOut, tween } from "../anim";
import { color } from "../tokens";

/**
 * macOS-style pointer that moves between two points (fractions of the
 * image box) and emits a click ring at `clickAt`.
 */
export const Cursor: React.FC<{
  width: number;
  height: number;
  from: [number, number];
  to: [number, number];
  start: number;
  dur: number;
  clickAt?: number;
  appear?: number;
}> = ({ width, height, from, to, start, dur, clickAt, appear = 0 }) => {
  const frame = useCurrentFrame();
  const p = tween(frame, start, dur, easeInOut);
  const x = (from[0] + (to[0] - from[0]) * p) * width;
  const y = (from[1] + (to[1] - from[1]) * p) * height;
  const opacity = tween(frame, appear, 10, easeOut);
  const ring = clickAt === undefined ? 0 : tween(frame, clickAt, 16, easeOut);
  const press = clickAt === undefined ? 0 : tween(frame, clickAt, 6, easeOut) - tween(frame, clickAt + 6, 8, easeOut);

  return (
    <div style={{ position: "absolute", left: x, top: y, opacity, pointerEvents: "none" }}>
      {ring > 0 && ring < 1 && (
        <div
          style={{
            position: "absolute",
            left: -22 * ring + 2,
            top: -22 * ring + 2,
            width: 44 * ring,
            height: 44 * ring,
            borderRadius: 999,
            border: `2px solid ${color.accent}`,
            opacity: 1 - ring,
          }}
        />
      )}
      <svg
        width={30}
        height={38}
        viewBox="0 0 24 30"
        style={{
          display: "block",
          transform: `scale(${1 - 0.12 * press})`,
          transformOrigin: "0 0",
          filter: "drop-shadow(0 2px 3px rgba(0,0,0,0.25))",
        }}
      >
        <path
          d="M3 2 L3 24 L8.6 18.6 L12.6 27.4 L16.4 25.7 L12.5 17 L20.2 17 Z"
          fill={color.ink}
          stroke={color.white}
          strokeWidth={1.6}
          strokeLinejoin="round"
        />
      </svg>
    </div>
  );
};
