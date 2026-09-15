import React from "react";
import { interpolate, useCurrentFrame } from "remotion";
import { SANS } from "../fonts";
import { CONTENT_H, OVERSCAN, sx, sy, WINDOW_W } from "../layout";
import { color } from "../tokens";

type Props = {
  text: string;
  from: number;
  /** frames to type the full string */
  duration: number;
  /** fractional box covering the placeholder to hide it */
  box: { x: number; y: number; w: number; h: number };
  fontSize: number;
};

/** Types `text` over the prompt placeholder, with a blinking caret. */
export const Typewriter: React.FC<Props> = ({ text, from, duration, box, fontSize }) => {
  const frame = useCurrentFrame();
  if (frame < from) return null;
  const n = Math.round(
    interpolate(frame, [from, from + duration], [0, text.length], {
      extrapolateLeft: "clamp",
      extrapolateRight: "clamp",
    }),
  );
  const caretOn = Math.floor(frame / 16) % 2 === 0 || n < text.length;
  return (
    <div
      style={{
        position: "absolute",
        left: sx(box.x) * WINDOW_W,
        top: sy(box.y) * CONTENT_H,
        width: box.w * OVERSCAN * WINDOW_W,
        height: box.h * OVERSCAN * CONTENT_H,
        backgroundColor: color.white,
        display: "flex",
        alignItems: "center",
        fontFamily: SANS,
        fontSize: fontSize * OVERSCAN,
        fontWeight: 400,
        letterSpacing: "-0.01em",
        color: color.ink,
        whiteSpace: "nowrap",
        overflow: "hidden",
      }}
    >
      <span>{text.slice(0, n)}</span>
      <span
        style={{
          display: "inline-block",
          width: 1.5,
          height: fontSize * 1.15,
          marginLeft: 1,
          backgroundColor: color.ink,
          opacity: caretOn ? 1 : 0,
        }}
      />
    </div>
  );
};
