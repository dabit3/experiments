import React from "react";
import { interpolate, useCurrentFrame } from "remotion";
import { color, ease } from "../theme";

type Props = {
  /** path of positions (px within parent) with the frame at which each is reached */
  path: { x: number; y: number; at: number }[];
  /** frames at which a click ring pulses */
  clicks?: number[];
  appearAt?: number;
};

export const Cursor: React.FC<Props> = ({ path, clicks = [], appearAt = 0 }) => {
  const frame = useCurrentFrame();
  const xs = path.map((p) => p.x);
  const ys = path.map((p) => p.y);
  const ts = path.map((p) => p.at);
  const x = interpolate(frame, ts, xs, { extrapolateLeft: "clamp", extrapolateRight: "clamp", easing: ease.inOut });
  const y = interpolate(frame, ts, ys, { extrapolateLeft: "clamp", extrapolateRight: "clamp", easing: ease.inOut });
  const opacity = interpolate(frame, [appearAt, appearAt + 8], [0, 1], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });

  return (
    <>
      {clicks.map((c) => {
        const t = interpolate(frame, [c, c + 14], [0, 1], { extrapolateLeft: "clamp", extrapolateRight: "clamp", easing: ease.out });
        if (frame < c || t >= 1) return null;
        const r = 14 + t * 26;
        return (
          <div
            key={c}
            style={{
              position: "absolute",
              left: x - r,
              top: y - r,
              width: r * 2,
              height: r * 2,
              borderRadius: 999,
              border: `3px solid ${color.accent}`,
              opacity: 1 - t,
            }}
          />
        );
      })}
      <svg
        width={30}
        height={38}
        viewBox="0 0 30 38"
        style={{ position: "absolute", left: x - 3, top: y - 2, opacity, filter: "drop-shadow(0 2px 3px rgba(0,0,0,0.35))" }}
      >
        <path d="M3 2 L3 30 L10 23 L15 35 L20 33 L15 21 L25 21 Z" fill={color.ink} stroke={color.white} strokeWidth={2.5} strokeLinejoin="round" />
      </svg>
    </>
  );
};
