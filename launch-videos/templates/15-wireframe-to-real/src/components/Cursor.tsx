import React from "react";
import { interpolate, useCurrentFrame } from "remotion";
import { easeInOut, easeOut, ms, prog } from "../anim";
import { color } from "../tokens";

export type CursorKey = {
  /** relative frame at which the cursor is at this point */
  at: number;
  /** position as a fraction of the stage (0..1) */
  x: number;
  y: number;
  /** emit a click when arriving here */
  click?: boolean;
};

type Props = {
  keys: CursorKey[];
  /** relative frame at which the cursor appears */
  from: number;
  /** relative frame at which the cursor fades out */
  to?: number;
  stageW: number;
  stageH: number;
};

/** A macOS-style pointer that moves between keyframes with ease-in-out. */
export const Cursor: React.FC<Props> = ({ keys, from, to, stageW, stageH }) => {
  const frame = useCurrentFrame();
  const appear = prog(frame, from, ms(300), easeOut);
  const leave = to === undefined ? 0 : prog(frame, to - ms(300), ms(300), easeOut);
  const opacity = appear * (1 - leave);
  if (opacity <= 0 || keys.length === 0) return null;

  let x = keys[0].x;
  let y = keys[0].y;
  for (let i = 1; i < keys.length; i++) {
    const a = keys[i - 1];
    const b = keys[i];
    if (frame >= b.at) {
      x = b.x;
      y = b.y;
    } else if (frame > a.at) {
      const t = prog(frame, a.at, b.at - a.at, easeInOut);
      x = a.x + (b.x - a.x) * t;
      y = a.y + (b.y - a.y) * t;
      break;
    }
  }

  // Click: a quick press (scale down) and release.
  let press = 0;
  for (const k of keys) {
    if (k.click) {
      const p = interpolate(frame, [k.at, k.at + 3, k.at + 8], [0, 1, 0], {
        extrapolateLeft: "clamp",
        extrapolateRight: "clamp",
      });
      press = Math.max(press, p);
    }
  }
  const scale = 1 - press * 0.15;

  return (
    <svg
      width={30}
      height={38}
      viewBox="0 0 30 38"
      style={{
        position: "absolute",
        left: x * stageW,
        top: y * stageH,
        opacity,
        transform: `scale(${scale})`,
        transformOrigin: "3px 3px",
        filter: "drop-shadow(0 2px 3px rgba(0,0,0,0.25))",
      }}
    >
      <path
        d="M3 2 L3 30 L10 23 L15.5 35 L20 33 L14.5 21.5 L24 21.5 Z"
        fill={color.ink}
        stroke={color.white}
        strokeWidth={2}
        strokeLinejoin="round"
      />
    </svg>
  );
};
