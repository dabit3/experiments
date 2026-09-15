import React from "react";
import { interpolate, useCurrentFrame } from "remotion";
import { DUR, FONT_MONO, FONT_SANS, HEIGHT, MARGIN, bp, easeIn, easeOut, type } from "../theme";

export type Line = { text: string; at: number; until?: number };

const RISE = 16;

/**
 * Narration: one or two short declarative lines, bottom-left inside the frame margin.
 * Entrance = fade + rise (ease-out). Exit = fade (ease-in). Only two motion types.
 */
export const Narration: React.FC<{ lines: Line[]; size?: number; maxWidth?: number }> = ({
  lines,
  size = 60,
  maxWidth = 1140,
}) => {
  const frame = useCurrentFrame();
  return (
    <div
      style={{
        position: "absolute",
        left: MARGIN,
        bottom: HEIGHT - 980,
        width: maxWidth,
        display: "flex",
        flexDirection: "column",
        gap: 8,
      }}
    >
      {lines.map((l) => {
        const enter = interpolate(frame, [l.at, l.at + DUR.base], [0, 1], {
          extrapolateLeft: "clamp",
          extrapolateRight: "clamp",
          easing: easeOut,
        });
        const exit =
          l.until === undefined
            ? 1
            : interpolate(frame, [l.until - DUR.fast, l.until], [1, 0], {
                extrapolateLeft: "clamp",
                extrapolateRight: "clamp",
                easing: easeIn,
              });
        const opacity = enter * exit;
        if (opacity <= 0 && frame > l.at) return null;
        return (
          <div
            key={l.text}
            style={{
              fontFamily: FONT_SANS,
              fontWeight: 500,
              fontSize: size,
              lineHeight: type.leading.heading,
              letterSpacing: type.tracking.heading,
              color: bp.text,
              opacity,
              transform: `translateY(${(1 - enter) * RISE}px)`,
            }}
          >
            {l.text}
          </div>
        );
      })}
    </div>
  );
};

/** Uppercase mono label — the drafting annotation voice. */
export const Label: React.FC<{
  children: React.ReactNode;
  size?: number;
  color?: string;
  style?: React.CSSProperties;
}> = ({ children, size = 20, color = bp.textDim, style }) => (
  <div
    style={{
      fontFamily: FONT_MONO,
      fontSize: size,
      fontWeight: 400,
      letterSpacing: type.tracking.caps,
      textTransform: "uppercase",
      color,
      lineHeight: 1,
      whiteSpace: "nowrap",
      ...style,
    }}
  >
    {children}
  </div>
);
