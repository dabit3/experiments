import React from "react";
import { AbsoluteFill, Img, interpolate, staticFile, useCurrentFrame } from "remotion";
import { copy } from "../content";
import { BRAND_MARK } from "../components/TileContent";
import { color, easeIn, easeOut, fontSans, type } from "../tokens";

// Picks up exactly where the brand tile finished expanding: the mark
// cross-fades into the lockup, and one line rises beneath it.
export const EndCard: React.FC = () => {
  const frame = useCurrentFrame();
  const markOut = interpolate(frame, [4, 18], [1, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeIn,
  });
  const lockupIn = interpolate(frame, [12, 40], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeOut,
  });
  const lineIn = interpolate(frame, [26, 54], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeOut,
  });

  return (
    <AbsoluteFill style={{ background: color.darkBg, alignItems: "center", justifyContent: "center" }}>
      <Img
        src={staticFile("brand/devin-mark-white.png")}
        style={{ position: "absolute", width: BRAND_MARK, height: BRAND_MARK, opacity: markOut }}
      />
      <div
        style={{
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          gap: 8,
          transform: `translateY(${(1 - lockupIn) * 16}px)`,
        }}
      >
        <Img
          src={staticFile("brand/devin-lockup-horizontal-white.png")}
          style={{ width: 560, opacity: lockupIn }}
        />
        <div
          style={{
            fontFamily: fontSans,
            fontSize: type.sizes1080p.body,
            fontWeight: 400,
            letterSpacing: type.tracking.body,
            lineHeight: type.leading.body,
            color: color.gray400,
            opacity: lineIn,
            transform: `translateY(${(1 - lineIn) * 10}px)`,
          }}
        >
          {copy.endLine}
        </div>
      </div>
    </AbsoluteFill>
  );
};
