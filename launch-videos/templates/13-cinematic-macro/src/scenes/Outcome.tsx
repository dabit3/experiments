import React from "react";
import { interpolate, useCurrentFrame } from "remotion";
import { MONO, SANS } from "../fonts";
import { easeIn, easeOut, tokens } from "../tokens";

const LINES = [
  "Minutes, not 20-minute CI round-trips.",
  "The only coding agent with a Mac cloud agent.",
  "Same security, same price as Linux.",
];

/** Three quiet statements on dark, one at a time. */
export const Outcome: React.FC<{ duration: number }> = ({ duration }) => {
  const frame = useCurrentFrame();
  const slot = Math.floor(duration / LINES.length);
  const enter = 16;
  const exit = 10;

  return (
    <div style={{ position: "absolute", inset: 0, background: tokens.color.darkBg }}>
      <div
        style={{
          position: "absolute",
          left: tokens.space.frameMargin1080p,
          top: "42%",
          fontFamily: MONO,
          fontWeight: 500,
          fontSize: 16,
          letterSpacing: tokens.type.tracking.caps,
          textTransform: "uppercase",
          color: tokens.color.gray500,
          opacity: interpolate(frame, [0, 20], [0, 1], { extrapolateRight: "clamp", easing: easeOut }),
        }}
      >
        Outcome
      </div>
      {LINES.map((line, i) => {
        const start = i * slot;
        const local = frame - start;
        if (local < 0 || local >= slot) return null;
        const inT = interpolate(local, [0, enter], [0, 1], {
          extrapolateLeft: "clamp",
          extrapolateRight: "clamp",
          easing: easeOut,
        });
        const outT =
          i === LINES.length - 1
            ? 1
            : interpolate(local, [slot - exit, slot], [1, 0], {
                extrapolateLeft: "clamp",
                extrapolateRight: "clamp",
                easing: easeIn,
              });
        return (
          <div
            key={line}
            style={{
              position: "absolute",
              left: tokens.space.frameMargin1080p,
              top: "42%",
              marginTop: 40,
              fontFamily: SANS,
              fontWeight: 500,
              fontSize: tokens.type.sizes1080p.h2,
              letterSpacing: tokens.type.tracking.heading,
              lineHeight: tokens.type.leading.heading,
              color: tokens.color.offWhite,
              opacity: Math.min(inT, outT),
              transform: `translateY(${(1 - inT) * 18}px)`,
              whiteSpace: "nowrap",
            }}
          >
            {line}
          </div>
        );
      })}
    </div>
  );
};
