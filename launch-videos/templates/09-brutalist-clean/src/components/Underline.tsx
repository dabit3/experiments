import React from "react";
import { interpolate, useCurrentFrame } from "remotion";
import { color, ease } from "../theme";

/** The single accent: a hard bar that draws in from the left. */
export const Underline: React.FC<{ at: number; width: number | string; height?: number; style?: React.CSSProperties }> = ({
  at,
  width,
  height = 12,
  style,
}) => {
  const frame = useCurrentFrame();
  const t = interpolate(frame, [at, at + 20], [0, 1], { extrapolateLeft: "clamp", extrapolateRight: "clamp", easing: ease.out });
  return (
    <div
      style={{
        width,
        height,
        background: color.accent,
        transform: `scaleX(${t})`,
        transformOrigin: "left center",
        ...style,
      }}
    />
  );
};
