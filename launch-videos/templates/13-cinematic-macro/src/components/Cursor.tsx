import React from "react";
import { interpolate, useCurrentFrame } from "remotion";
import { easeInOut } from "../tokens";
import type { Project } from "./MacroShot";

export type CursorKey = { frame: number; x: number; y: number };

type Props = {
  /** Image-space keyframes; the cursor eases between consecutive keys. */
  keys: CursorKey[];
  /** Frames at which a click pulse happens. */
  clicks?: number[];
  project: Project;
  size?: number;
};

/** macOS-style arrow cursor drawn in output space so it stays crisp under the dolly. */
export const Cursor: React.FC<Props> = ({ keys, clicks = [], project, size = 34 }) => {
  const frame = useCurrentFrame();

  let x = keys[0].x;
  let y = keys[0].y;
  for (let i = 0; i < keys.length - 1; i++) {
    const a = keys[i];
    const b = keys[i + 1];
    if (frame >= b.frame) {
      x = b.x;
      y = b.y;
      continue;
    }
    if (frame >= a.frame) {
      const t = interpolate(frame, [a.frame, b.frame], [0, 1], { easing: easeInOut });
      x = a.x + (b.x - a.x) * t;
      y = a.y + (b.y - a.y) * t;
      break;
    }
  }

  let press = 0;
  for (const c of clicks) {
    const d = frame - c;
    if (d >= 0 && d < 8) press = Math.max(press, d < 3 ? d / 3 : 1 - (d - 3) / 5);
  }
  const scale = 1 - press * 0.12;

  const p = project(x, y);
  return (
    <svg
      width={size}
      height={size * 1.5}
      viewBox="0 0 20 30"
      style={{
        position: "absolute",
        left: p.x,
        top: p.y,
        transform: `scale(${scale})`,
        transformOrigin: "1px 1px",
        filter: "drop-shadow(0 2px 3px rgba(0,0,0,0.35))",
      }}
    >
      <path
        d="M1.5 1.5 L1.5 22.5 L6.6 17.6 L10.4 26.2 L14.2 24.5 L10.4 16.1 L17.6 16.1 Z"
        fill="#fff"
        stroke="#191919"
        strokeWidth="1.6"
        strokeLinejoin="round"
      />
    </svg>
  );
};
