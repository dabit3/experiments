import React from "react";
import { AbsoluteFill, Img, staticFile, useCurrentFrame } from "remotion";
import { enter } from "../components/anim";
import { color, font, sizes, tracking, weight } from "../theme";

export const EndCard: React.FC = () => {
  const frame = useCurrentFrame();
  const logoP = enter(frame, 4, 30);
  const lineP = enter(frame, 22, 26);
  const urlP = enter(frame, 40, 26);
  return (
    <AbsoluteFill style={{ justifyContent: "center", alignItems: "center" }}>
      <Img
        src={staticFile("brand/devin-lockup-horizontal-black.png")}
        style={{
          width: 560,
          opacity: logoP,
          transform: `translateY(${(1 - logoP) * 16}px)`,
          marginBottom: 8,
        }}
      />
      <div
        style={{
          fontFamily: font.sans,
          fontSize: sizes.h3,
          fontWeight: weight.regular,
          letterSpacing: tracking.body,
          color: color.ink,
          opacity: lineP,
          transform: `translateY(${(1 - lineP) * 12}px)`,
        }}
      >
        Build, run and test iOS apps in the cloud.
      </div>
      <div
        style={{
          marginTop: 28,
          fontFamily: font.mono,
          fontSize: sizes.caption,
          fontWeight: weight.medium,
          letterSpacing: tracking.caps,
          color: color.gray500,
          opacity: urlP,
        }}
      >
        devin.ai
      </div>
    </AbsoluteFill>
  );
};
