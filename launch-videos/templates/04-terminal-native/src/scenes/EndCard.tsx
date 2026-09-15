import React from "react";
import { AbsoluteFill, Easing, Img, interpolate, staticFile, useCurrentFrame } from "remotion";
import { color, easeOut, font, type } from "../tokens";

const fadeIn = (frame: number, at: number, len = 20) =>
  interpolate(frame, [at, at + len], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.bezier(...easeOut),
  });

export const EndCard: React.FC = () => {
  const frame = useCurrentFrame();
  return (
    <AbsoluteFill
      style={{
        backgroundColor: color.darkBg,
        alignItems: "center",
        justifyContent: "center",
      }}
    >
      <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 36, marginTop: -20 }}>
        <Img
          src={staticFile("brand/devin-lockup-horizontal-white.png")}
          style={{ width: 520, opacity: fadeIn(frame, 4) }}
        />
        <div
          style={{
            fontFamily: font.sans,
            fontWeight: type.weights.medium,
            fontSize: type.sizes1080p.h3,
            letterSpacing: type.tracking.heading,
            lineHeight: type.leading.heading,
            color: color.paper,
            opacity: fadeIn(frame, 18),
          }}
        >
          Build, run and test iOS apps in the cloud.
        </div>
        <div
          style={{
            fontFamily: font.mono,
            fontSize: type.sizes1080p.caption,
            letterSpacing: type.tracking.caps,
            color: color.gray400,
            opacity: fadeIn(frame, 30),
          }}
        >
          devin.ai
        </div>
      </div>
    </AbsoluteFill>
  );
};
