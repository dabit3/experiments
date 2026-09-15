import React from "react";
import { Img, interpolate, staticFile, useCurrentFrame } from "remotion";
import { SANS } from "../fonts";
import { easeOut, tokens } from "../tokens";

/** Devin lockup on dark with one closing line. */
export const EndCard: React.FC<{ duration: number }> = () => {
  const frame = useCurrentFrame();
  const logo = interpolate(frame, [6, 34], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeOut,
  });
  const line = interpolate(frame, [26, 52], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeOut,
  });

  return (
    <div
      style={{
        position: "absolute",
        inset: 0,
        background: tokens.color.darkBg,
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "center",
        gap: 28,
      }}
    >
      <Img
        src={staticFile("brand/devin-lockup-horizontal-white.png")}
        style={{
          width: 420,
          height: "auto",
          opacity: logo,
          transform: `translateY(${(1 - logo) * 12}px)`,
        }}
      />
      <div
        style={{
          fontFamily: SANS,
          fontWeight: 400,
          fontSize: tokens.type.sizes1080p.body,
          letterSpacing: tokens.type.tracking.body,
          color: tokens.color.gray400,
          opacity: line,
          transform: `translateY(${(1 - line) * 10}px)`,
        }}
      >
        Build, run and test iOS apps in the cloud.
      </div>
    </div>
  );
};
