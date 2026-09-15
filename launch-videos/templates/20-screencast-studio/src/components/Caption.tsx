import React from "react";
import { useCurrentFrame } from "remotion";
import { easeIn, easeOut, progress } from "../anim";
import { SANS } from "../fonts";
import { CAPTION_H, CAPTION_TOP } from "../layout";
import { color, radius, type } from "../tokens";

type Props = {
  /** local frame the caption starts appearing */
  from: number;
  /** local frame the caption is fully gone */
  to: number;
  children: React.ReactNode;
};

const IN = 12;
const OUT = 8;

/** Narration line beneath the window. Fade + 12px rise on entry, fade on exit. */
export const Caption: React.FC<Props> = ({ from, to, children }) => {
  const frame = useCurrentFrame();
  if (frame < from || frame >= to) return null;
  const i = progress(frame, from, from + IN, easeOut);
  const o = 1 - progress(frame, to - OUT, to, easeIn);
  const opacity = Math.min(i, o);
  const rise = (1 - i) * 12;
  return (
    <div
      style={{
        position: "absolute",
        top: CAPTION_TOP,
        left: 0,
        right: 0,
        height: CAPTION_H,
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        pointerEvents: "none",
      }}
    >
      <div
        style={{
          opacity,
          transform: `translateY(${rise}px)`,
          backgroundColor: color.ink,
          color: color.white,
          borderRadius: radius.md,
          padding: "12px 26px",
          fontFamily: SANS,
          fontSize: type.sizes1080p.body,
          fontWeight: 500,
          letterSpacing: type.tracking.body,
          lineHeight: 1.3,
          textAlign: "center",
          whiteSpace: "pre-line",
          maxWidth: 1200,
        }}
      >
        {children}
      </div>
    </div>
  );
};
