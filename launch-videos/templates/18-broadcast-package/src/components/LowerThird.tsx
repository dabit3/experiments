import React from "react";
import { useCurrentFrame } from "remotion";
import type { Brand } from "../schema";
import { enter, exit } from "../motion";
import { type } from "../layout";

type Props = {
  brand: Brand;
  text: string;
  kicker: string;
  from: number;
  durationInFrames: number;
  transitionFrames: number;
  left: number;
  top: number;
  maxWidth: number;
};

/**
 * Broadcast-style lower third: an accent rule, a small kicker and one caption line.
 * Wipes in from the left rule and fades out whole; never overlays the footage.
 */
export const LowerThird: React.FC<Props> = ({
  brand,
  text,
  kicker,
  from,
  durationInFrames,
  transitionFrames,
  left,
  top,
  maxWidth,
}) => {
  const frame = useCurrentFrame();
  if (frame < from || frame >= from + durationInFrames) {
    return null;
  }
  const pIn = enter(frame, from, transitionFrames);
  const p = Math.min(pIn, exit(frame, from + durationInFrames, transitionFrames));
  const ruleH = 64;
  return (
    <div
      style={{
        position: "absolute",
        left,
        top,
        display: "flex",
        alignItems: "stretch",
        gap: 20,
        maxWidth,
        opacity: p,
      }}
    >
      <div
        style={{
          width: 4,
          height: ruleH,
          background: brand.accent,
          transform: `scaleY(${p})`,
          transformOrigin: "top",
        }}
      />
      <div
        style={{
          display: "flex",
          flexDirection: "column",
          justifyContent: "center",
          transform: `translateX(${(1 - pIn) * -24}px)`,
          clipPath: `inset(0 ${(1 - pIn) * 100}% 0 0)`,
        }}
      >
        <div
          style={{
            ...type.eyebrow,
            fontFamily: brand.fontFamily,
            color: brand.inkMuted,
            marginBottom: 6,
          }}
        >
          {kicker}
        </div>
        <div
          style={{
            ...type.h5,
            fontFamily: brand.fontFamily,
            color: brand.ink,
            whiteSpace: "nowrap",
          }}
        >
          {text}
        </div>
      </div>
    </div>
  );
};
