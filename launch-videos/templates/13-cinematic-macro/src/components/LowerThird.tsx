import React from "react";
import { interpolate, useCurrentFrame } from "remotion";
import { MONO, SANS } from "../fonts";
import { easeIn, easeOut, FRAME_MARGIN, tokens, WIDTH } from "../tokens";

type Props = {
  text: string;
  /** Small mono eyebrow, e.g. "01  BUILD & RUN". */
  label?: string;
  from: number;
  duration: number;
  enter?: number;
  exit?: number;
};

/** Quiet lower-third: one line, bottom-left of the picture, ease-out in / ease-in out. */
export const LowerThird: React.FC<Props> = ({
  text,
  label,
  from,
  duration,
  enter = 18,
  exit = 12,
}) => {
  const frame = useCurrentFrame();
  const local = frame - from;
  if (local < 0 || local > duration) return null;

  const inT = interpolate(local, [0, enter], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeOut,
  });
  const outT = interpolate(local, [duration - exit, duration], [1, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeIn,
  });
  const opacity = Math.min(inT, outT);
  const rise = (1 - inT) * 14;

  return (
    <div
      style={{
        position: "absolute",
        left: FRAME_MARGIN,
        bottom: 64,
        maxWidth: WIDTH - FRAME_MARGIN * 2,
        opacity,
        transform: `translateY(${rise}px)`,
        display: "flex",
        flexDirection: "column",
        gap: 12,
        pointerEvents: "none",
      }}
    >
      {label ? (
        <div
          style={{
            fontFamily: MONO,
            fontWeight: 500,
            fontSize: 17,
            letterSpacing: tokens.type.tracking.caps,
            textTransform: "uppercase",
            color: tokens.color.gray300,
            textShadow: "0 1px 8px rgba(0,0,0,0.4)",
            lineHeight: 1,
          }}
        >
          {label}
        </div>
      ) : null}
      <div
        style={{
          fontFamily: SANS,
          fontWeight: 500,
          fontSize: 30,
          letterSpacing: tokens.type.tracking.body,
          color: tokens.color.offWhite,
          lineHeight: 1.2,
          whiteSpace: "nowrap",
          textShadow: "0 1px 12px rgba(0,0,0,0.35)",
        }}
      >
        {text}
      </div>
    </div>
  );
};
