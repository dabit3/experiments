import React from "react";
import { AbsoluteFill, Img, staticFile, useCurrentFrame } from "remotion";
import { easeOut, lerp, progress } from "../anim";
import { MONO, SANS } from "../fonts";
import { color, type } from "../tokens";

/** 8. End card — lockup, one line, URL. */
export const EndCard: React.FC = () => {
  const frame = useCurrentFrame();
  const logo = progress(frame, 0, 28, easeOut);
  const line = progress(frame, 12, 38, easeOut);
  const url = progress(frame, 26, 50, easeOut);
  return (
    <AbsoluteFill style={{ alignItems: "center", justifyContent: "center" }}>
      <Img
        src={staticFile("brand/devin-lockup-horizontal-black.png")}
        style={{
          width: 400,
          height: 400 / (2984 / 1024),
          objectFit: "contain",
          opacity: logo,
          transform: `scale(${lerp(0.96, 1, logo)})`,
        }}
      />
      <div
        style={{
          marginTop: 28,
          fontFamily: SANS,
          fontSize: 34,
          fontWeight: 400,
          letterSpacing: type.tracking.body,
          color: color.gray700,
          opacity: line,
          transform: `translateY(${(1 - line) * 12}px)`,
        }}
      >
        Build, run and test iOS apps in the cloud.
      </div>
      <div
        style={{
          position: "absolute",
          bottom: 120,
          fontFamily: MONO,
          fontSize: type.sizes1080p.label,
          fontWeight: 500,
          letterSpacing: type.tracking.caps,
          textTransform: "uppercase",
          color: color.gray500,
          opacity: url,
        }}
      >
        devin.ai
      </div>
    </AbsoluteFill>
  );
};
