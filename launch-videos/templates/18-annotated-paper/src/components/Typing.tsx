import React from "react";
import { interpolate, useCurrentFrame } from "remotion";
import { useFigure } from "./Figure";
import { color, font } from "../theme";

type TypingProps = {
  /** Normalised rect of the placeholder text to cover. */
  cover: { x: number; y: number; w: number; h: number };
  text: string;
  at: number;
  /** Characters per second. */
  cps?: number;
  /** Font size as a fraction of source-image height. */
  sizeN: number;
};

/** Types a prompt over the (masked) placeholder of a screenshot's input box. */
export const Typing: React.FC<TypingProps> = ({ cover, text, at, cps = 34, sizeN }) => {
  const frame = useCurrentFrame();
  const fig = useFigure();
  const tl = fig.toPx(cover.x, cover.y);
  const br = fig.toPx(cover.x + cover.w, cover.y + cover.h);
  const fontSize = sizeN * fig.scaleY;
  const chars = Math.max(0, Math.floor(((frame - at) / 30) * cps));
  const shown = text.slice(0, chars);
  const done = chars >= text.length;
  const caretOn = done ? Math.floor(frame / 15) % 2 === 0 : true;
  const visible = interpolate(frame, [at - 1, at], [0, 1], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  return (
    <div
      style={{
        position: "absolute",
        left: tl.x,
        top: tl.y,
        width: br.x - tl.x,
        height: br.y - tl.y,
        backgroundColor: color.white,
        opacity: visible,
        display: "flex",
        alignItems: "center",
        fontFamily: font.sans,
        fontWeight: 400,
        fontSize,
        letterSpacing: "-0.01em",
        color: color.ink,
        whiteSpace: "nowrap",
        overflow: "hidden",
      }}
    >
      {shown}
      <span
        style={{
          display: "inline-block",
          width: Math.max(1.5, fontSize * 0.07),
          height: fontSize * 1.1,
          marginLeft: 2,
          backgroundColor: color.ink,
          opacity: caretOn ? 1 : 0,
        }}
      />
    </div>
  );
};
