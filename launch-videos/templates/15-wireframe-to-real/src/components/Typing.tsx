import React from "react";
import { useCurrentFrame } from "remotion";
import { color, FONT_SANS } from "../tokens";

type Props = {
  text: string;
  /** relative frame at which typing starts */
  from: number;
  /** frames per character */
  cps?: number;
  /** position + size in stage fractions */
  x: number;
  y: number;
  w: number;
  h: number;
  fontSize: number;
  stageW: number;
  stageH: number;
  /** background colour that hides the placeholder underneath */
  cover: string;
};

/** Types a prompt over the (placeholder) input of a screenshot, with a caret. */
export const Typing: React.FC<Props> = ({
  text,
  from,
  cps = 1.1,
  x,
  y,
  w,
  h,
  fontSize,
  stageW,
  stageH,
  cover,
}) => {
  const frame = useCurrentFrame();
  if (frame < from) return null;
  const chars = Math.min(text.length, Math.floor((frame - from) / cps));
  const done = chars >= text.length;
  const caretOn = done ? Math.floor((frame - from) / 16) % 2 === 0 : true;
  return (
    <div
      style={{
        position: "absolute",
        left: x * stageW,
        top: y * stageH,
        width: w * stageW,
        height: h * stageH,
        background: cover,
        display: "flex",
        alignItems: "center",
        fontFamily: FONT_SANS,
        fontSize: fontSize * (stageW / 1240),
        color: color.ink,
        letterSpacing: "-0.01em",
        whiteSpace: "nowrap",
        overflow: "hidden",
      }}
    >
      <span>{text.slice(0, chars)}</span>
      <span
        style={{
          display: "inline-block",
          width: 1.5,
          height: fontSize * (stageW / 1240) * 1.15,
          background: color.ink,
          marginLeft: 1,
          opacity: caretOn ? 1 : 0,
        }}
      />
    </div>
  );
};
