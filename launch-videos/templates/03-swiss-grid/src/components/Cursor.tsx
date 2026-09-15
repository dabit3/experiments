import React from "react";
import { color } from "../theme";

type Props = {
  /** Position as fractions of the parent figure. */
  x: number;
  y: number;
  opacity?: number;
  /** 0–1: pressed state shrinks the pointer slightly. */
  press?: number;
};

/** macOS-style arrow pointer overlay. */
export const Cursor: React.FC<Props> = ({ x, y, opacity = 1, press = 0 }) => (
  <svg
    width={44}
    height={52}
    viewBox="0 0 22 26"
    style={{
      position: "absolute",
      left: `${x * 100}%`,
      top: `${y * 100}%`,
      opacity,
      transform: `translate(-2px, -2px) scale(${1 - press * 0.12})`,
      transformOrigin: "2px 2px",
      filter: "drop-shadow(0 2px 4px rgba(0,0,0,0.25))",
    }}
  >
    <path
      d="M2 1.5 L2 20 L7 15.5 L10.5 23.5 L14 22 L10.5 14.5 L17 14.5 Z"
      fill={color.ink}
      stroke={color.white}
      strokeWidth={1.5}
      strokeLinejoin="round"
    />
  </svg>
);
