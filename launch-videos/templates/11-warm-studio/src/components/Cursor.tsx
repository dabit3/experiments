import React from "react";
import { color } from "../tokens";

type CursorProps = {
  /** Position of the pointer tip, in % of the parent. */
  x: number;
  y: number;
  size?: number;
  opacity?: number;
};

export const Cursor: React.FC<CursorProps> = ({ x, y, size = 26, opacity = 1 }) => (
  <svg
    width={size}
    height={size}
    viewBox="0 0 24 24"
    style={{
      position: "absolute",
      left: `${x}%`,
      top: `${y}%`,
      opacity,
      filter: "drop-shadow(0 2px 4px rgba(0,0,0,0.25))",
    }}
  >
    <path
      d="M4 2.5 L19.5 12.2 L12.6 13.6 L9.2 20.3 Z"
      fill={color.ink}
      stroke={color.white}
      strokeWidth={1.4}
      strokeLinejoin="round"
    />
  </svg>
);
