import React from "react";
import { AbsoluteFill, Img, interpolate, staticFile, useCurrentFrame } from "remotion";
import { color, ease, font, TICKER_HEIGHT } from "../theme";

export const EndCard: React.FC = () => {
  const frame = useCurrentFrame();
  const logo = interpolate(frame, [0, 20], [0, 1], { extrapolateLeft: "clamp", extrapolateRight: "clamp", easing: ease.out });
  const line = interpolate(frame, [14, 34], [0, 1], { extrapolateLeft: "clamp", extrapolateRight: "clamp", easing: ease.out });

  return (
    <AbsoluteFill style={{ backgroundColor: color.ink }}>
      <div
        style={{
          position: "absolute",
          left: 0,
          right: 0,
          top: 0,
          bottom: TICKER_HEIGHT,
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          justifyContent: "center",
          gap: 56,
        }}
      >
        <Img
          src={staticFile("brand/devin-lockup-horizontal-white.png")}
          style={{ width: 620, opacity: logo, transform: `translateY(${(1 - logo) * 20}px)` }}
        />
        <div
          style={{
            opacity: line,
            transform: `translateY(${(1 - line) * 20}px)`,
            display: "flex",
            flexDirection: "column",
            alignItems: "center",
            gap: 28,
          }}
        >
          <div
            style={{
              fontFamily: font.sans,
              fontWeight: font.weight.medium,
              fontSize: font.size.h3,
              letterSpacing: font.tracking.heading,
              color: color.paper,
            }}
          >
            Build, run and test iOS apps in the cloud.
          </div>
          <div
            style={{
              fontFamily: font.mono,
              fontSize: font.size.label,
              fontWeight: 500,
              letterSpacing: font.tracking.caps,
              textTransform: "uppercase",
              color: color.gray400,
            }}
          >
            devin.ai
          </div>
        </div>
      </div>
    </AbsoluteFill>
  );
};
