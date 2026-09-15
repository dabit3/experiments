import React from "react";
import { interpolate } from "remotion";
import type { CursorKey } from "../content";
import { color, easeInOut, easeOut } from "../tokens";

type Props = { keys: CursorKey[]; frame: number; width: number; height: number };

// macOS-style pointer that eases between keyframes; a click emits one ring.
export const Cursor: React.FC<Props> = ({ keys, frame, width, height }) => {
  if (keys.length === 0 || frame < keys[0].frame) return null;
  let a = keys[0];
  let b = keys[0];
  for (let i = 0; i < keys.length - 1; i++) {
    if (frame >= keys[i].frame) {
      a = keys[i];
      b = keys[i + 1];
    }
  }
  if (frame >= keys[keys.length - 1].frame) a = b = keys[keys.length - 1];
  const t = a === b ? 1 : interpolate(frame, [a.frame, b.frame], [0, 1], { easing: easeInOut });
  const x = (a.x + (b.x - a.x) * t) * width;
  const y = (a.y + (b.y - a.y) * t) * height;
  const appear = interpolate(frame, [keys[0].frame, keys[0].frame + 10], [0, 1], {
    extrapolateRight: "clamp",
    easing: easeOut,
  });

  const rings = keys.filter((k) => k.click && frame >= k.frame && frame < k.frame + 24);

  return (
    <>
      {rings.map((k) => {
        const p = interpolate(frame, [k.frame, k.frame + 24], [0, 1], { easing: easeOut });
        const size = 16 + p * 64;
        return (
          <div
            key={k.frame}
            style={{
              position: "absolute",
              left: k.x * width - size / 2,
              top: k.y * height - size / 2,
              width: size,
              height: size,
              borderRadius: 999,
              border: `2px solid ${color.accent}`,
              opacity: 1 - p,
            }}
          />
        );
      })}
      <svg
        width={34}
        height={40}
        viewBox="0 0 17 20"
        style={{
          position: "absolute",
          left: x,
          top: y,
          opacity: appear,
          filter: "drop-shadow(0 2px 3px rgba(0,0,0,0.35))",
        }}
      >
        <path
          d="M1 1L1 15.5L4.8 12L7.6 18.5L10.3 17.3L7.6 11L12.8 11Z"
          fill={color.white}
          stroke={color.ink}
          strokeWidth={1.2}
          strokeLinejoin="round"
        />
      </svg>
    </>
  );
};
