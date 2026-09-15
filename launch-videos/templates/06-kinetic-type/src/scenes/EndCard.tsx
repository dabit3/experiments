import React from "react";
import {
  AbsoluteFill,
  Easing,
  Img,
  interpolate,
  staticFile,
  useCurrentFrame,
} from "remotion";
import { MONO, SANS } from "../fonts";
import { beats, color, EASE_OUT, type } from "../tokens";

const slam = (frame: number, at: number, len = 6) => {
  const p = interpolate(frame, [at, at + len], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.bezier(...EASE_OUT),
  });
  return {
    opacity: interpolate(p, [0, 0.5], [0, 1], { extrapolateRight: "clamp" }),
    transform: `scale(${interpolate(p, [0, 1], [1.12, 1])})`,
  };
};

/** 8 beats. Lockup on beat 0, tagline on beat 2, URL on beat 5. */
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
      <div style={{ display: "flex", flexDirection: "column", alignItems: "center" }}>
        <Img
          src={staticFile("brand/devin-lockup-horizontal-white.png")}
          style={{ width: 760, height: "auto", display: "block", ...slam(frame, 0) }}
        />
        <div
          style={{
            marginTop: 8,
            fontFamily: SANS,
            fontWeight: type.weights.medium,
            fontSize: type.sizes1080p.h2,
            letterSpacing: type.tracking.heading,
            lineHeight: type.leading.tight,
            color: color.white,
            whiteSpace: "nowrap",
            ...slam(frame, beats(2)),
          }}
        >
          Build, run and test iOS apps in the cloud.
        </div>
        <div
          style={{
            marginTop: 48,
            fontFamily: MONO,
            fontWeight: type.weights.medium,
            fontSize: type.sizes1080p.body,
            letterSpacing: type.tracking.caps,
            color: color.gray400,
            ...slam(frame, beats(5)),
          }}
        >
          devin.ai
        </div>
      </div>
    </AbsoluteFill>
  );
};
