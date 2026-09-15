import React from "react";
import { interpolate, useCurrentFrame } from "remotion";
import { easeInOut, easeOut } from "../tokens";

type Props = {
  /** Path of [frame, x, y] keyframes, in the parent's px. */
  path: [number, number, number][];
  /** Frames at which a click happens (a soft ring expands and fades). */
  clicks?: number[];
  /** Frame at which the pointer has fully faded out. */
  until?: number;
  scale?: number;
};

/** macOS-style pointer that eases between keyframes; a click is a fading ring — fade + move only. */
export const Cursor: React.FC<Props> = ({ path, clicks = [], until = Number.POSITIVE_INFINITY, scale = 1 }) => {
  const frame = useCurrentFrame();
  const frames = path.map((p) => p[0]);
  const x = interpolate(frame, frames, path.map((p) => p[1]), {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeInOut,
  });
  const y = interpolate(frame, frames, path.map((p) => p[2]), {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeInOut,
  });
  const enter = interpolate(frame, [frames[0] - 12, frames[0]], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeOut,
  });
  const exit = Number.isFinite(until)
    ? interpolate(frame, [until - 14, until], [1, 0], {
        extrapolateLeft: "clamp",
        extrapolateRight: "clamp",
      })
    : 1;

  return (
    <div style={{ position: "absolute", left: x, top: y, opacity: Math.min(enter, exit), pointerEvents: "none" }}>
      {clicks.map((c) => {
        const r = interpolate(frame, [c, c + 16], [8, 34], {
          extrapolateLeft: "clamp",
          extrapolateRight: "clamp",
          easing: easeOut,
        });
        const o = interpolate(frame, [c, c + 16], [0.45, 0], {
          extrapolateLeft: "clamp",
          extrapolateRight: "clamp",
        });
        if (frame < c) return null;
        return (
          <div
            key={c}
            style={{
              position: "absolute",
              left: -r,
              top: -r,
              width: r * 2,
              height: r * 2,
              borderRadius: 999,
              border: `2px solid rgba(25,25,25,${o})`,
            }}
          />
        );
      })}
      <svg
        width={28 * scale}
        height={36 * scale}
        viewBox="0 0 28 36"
        style={{ position: "absolute", left: -2, top: -2 }}
      >
        <path
          d="M2 2 L2 27 L8.5 21.5 L13 31.5 L17.5 29.5 L13 19.5 L21.5 19.5 Z"
          fill="#191919"
          stroke="#FFFFFF"
          strokeWidth={2.2}
          strokeLinejoin="round"
        />
      </svg>
    </div>
  );
};
