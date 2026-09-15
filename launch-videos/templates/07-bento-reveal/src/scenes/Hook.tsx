import React from "react";
import { AbsoluteFill, interpolate, useCurrentFrame, useVideoConfig } from "remotion";
import { copy } from "../content";
import { eyebrowStyle } from "../components/TileContent";
import { color, easeIn, easeOut, fontSans, type } from "../tokens";

const fadeUp = (frame: number, from: number, len = 30) =>
  interpolate(frame, [from, from + len], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeOut,
  });

export const Hook: React.FC = () => {
  const frame = useCurrentFrame();
  const { durationInFrames } = useVideoConfig();
  const eyebrow = fadeUp(frame, 4);
  const hero = fadeUp(frame, 12);
  const exit = interpolate(frame, [durationInFrames - 14, durationInFrames], [1, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeIn,
  });

  return (
    <AbsoluteFill
      style={{
        background: color.paper,
        alignItems: "center",
        justifyContent: "center",
        opacity: exit,
      }}
    >
      <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 36 }}>
        <div
          style={{
            ...eyebrowStyle,
            color: color.gray500,
            opacity: eyebrow,
            transform: `translateY(${(1 - eyebrow) * 12}px)`,
          }}
        >
          {copy.hookEyebrow}
        </div>
        <div
          style={{
            fontFamily: fontSans,
            fontSize: type.sizes1080p.hero,
            fontWeight: 500,
            letterSpacing: type.tracking.hero,
            lineHeight: type.leading.tight,
            color: color.ink,
            opacity: hero,
            transform: `translateY(${(1 - hero) * 24}px)`,
          }}
        >
          {copy.hook}
        </div>
      </div>
    </AbsoluteFill>
  );
};
