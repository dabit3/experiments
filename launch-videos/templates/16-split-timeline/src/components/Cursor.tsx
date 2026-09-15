import React from "react";
import { useCurrentFrame } from "remotion";
import { color } from "../theme";
import { lerp, lifetime, move } from "./anim";

export type CursorStop = { frame: number; x: number; y: number; click?: boolean };

/**
 * A pointer that glides between stops (percent coordinates of the parent figure), ease-in-out.
 * A stop with `click` briefly scales the cursor down at arrival.
 */
export const Cursor: React.FC<{ stops: CursorStop[]; hideAt?: number }> = ({ stops, hideAt }) => {
  const frame = useCurrentFrame();
  const first = stops[0];
  let x = first.x;
  let y = first.y;
  let pressed = 0;
  for (let i = 1; i < stops.length; i++) {
    const a = stops[i - 1];
    const b = stops[i];
    const t = move(frame, a.frame, b.frame - a.frame);
    x = lerp(x, b.x, t);
    y = lerp(y, b.y, t);
    if (b.click) {
      const down = move(frame, b.frame, 5);
      const up = move(frame, b.frame + 5, 6);
      pressed = Math.max(pressed, down - up);
    }
  }
  const opacity = lifetime(frame, first.frame, hideAt, 10, 8);
  const scale = 1 - 0.12 * pressed;
  return (
    <svg
      width={28}
      height={34}
      viewBox="0 0 28 34"
      style={{
        position: "absolute",
        left: `${x}%`,
        top: `${y}%`,
        opacity,
        transform: `scale(${scale})`,
        transformOrigin: "4px 4px",
        filter: "drop-shadow(0 2px 3px rgba(0,0,0,0.25))",
      }}
    >
      <path
        d="M4 3 L4 26 L10 20.5 L14.5 30 L18.5 28.2 L14 18.8 L22 18.8 Z"
        fill={color.ink}
        stroke={color.white}
        strokeWidth={2}
        strokeLinejoin="round"
      />
    </svg>
  );
};
