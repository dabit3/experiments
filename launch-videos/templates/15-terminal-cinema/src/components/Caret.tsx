import React from "react";
import { useCurrentFrame } from "remotion";
import type { Brand, Cursor } from "../schema";

type Props = {
  brand: Brand;
  cursor: Cursor;
  fontSize: number;
  blinking: boolean;
  opacity?: number;
};

export const Caret: React.FC<Props> = ({ brand, cursor, fontSize, blinking, opacity = 1 }) => {
  const frame = useCurrentFrame();
  const on = !blinking || frame % cursor.blinkFrames < cursor.blinkFrames / 2;
  const color = cursor.color === "accent" ? brand.accent : brand.ink;
  const width = cursor.glyph === "bar" ? Math.max(2, fontSize * 0.06) : fontSize * 0.55;
  const height = cursor.glyph === "underscore" ? Math.max(2, fontSize * 0.08) : fontSize * 0.95;

  return (
    <span
      style={{
        display: "inline-block",
        width,
        height,
        marginLeft: fontSize * 0.12,
        verticalAlign: cursor.glyph === "underscore" ? "baseline" : "text-bottom",
        backgroundColor: color,
        opacity: on ? opacity : 0,
      }}
    />
  );
};
