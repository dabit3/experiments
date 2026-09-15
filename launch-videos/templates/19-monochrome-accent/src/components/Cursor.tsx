import React from "react";
import { interpolate, useCurrentFrame } from "remotion";
import { color, easeInOut, easeOut } from "../theme";

export type CursorStop = { x: number; y: number; at: number; click?: boolean };

/**
 * Pointer that moves between stops (ease-in-out) and emits an accent ring on click stops.
 * Coordinates are in px relative to the parent.
 */
export const Cursor: React.FC<{ stops: CursorStop[]; appearAt?: number }> = ({
  stops,
  appearAt = 0,
}) => {
  const frame = useCurrentFrame();
  const xs = stops.map((s) => s.x);
  const ys = stops.map((s) => s.y);
  const ts = stops.map((s) => s.at);
  const opts = {
    extrapolateLeft: "clamp" as const,
    extrapolateRight: "clamp" as const,
    easing: easeInOut,
  };
  const x = stops.length > 1 ? interpolate(frame, ts, xs, opts) : xs[0];
  const y = stops.length > 1 ? interpolate(frame, ts, ys, opts) : ys[0];
  const opacity = interpolate(frame, [appearAt, appearAt + 10], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeOut,
  });

  return (
    <>
      {stops
        .filter((s) => s.click)
        .map((s) => {
          const p = interpolate(frame, [s.at, s.at + 22], [0, 1], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
            easing: easeOut,
          });
          if (p <= 0 || p >= 1) return null;
          const r = 10 + p * 34;
          return (
            <div
              key={s.at}
              style={{
                position: "absolute",
                left: s.x - r,
                top: s.y - r,
                width: r * 2,
                height: r * 2,
                borderRadius: "50%",
                border: `3px solid ${color.accent}`,
                opacity: 1 - p,
              }}
            />
          );
        })}
      <svg
        width="34"
        height="40"
        viewBox="0 0 17 20"
        style={{ position: "absolute", left: x, top: y, opacity }}
      >
        <path
          d="M1 1 L1 15.5 L4.6 12.2 L7.4 18.6 L10.2 17.4 L7.5 11.1 L12.4 11 Z"
          fill={color.black}
          stroke={color.white}
          strokeWidth="1.3"
          strokeLinejoin="round"
        />
      </svg>
    </>
  );
};
