import React from "react";
import { Img, interpolate, staticFile, useCurrentFrame } from "remotion";
import { Headline } from "../components/Headline";
import { mono } from "../fonts";
import { color, easeOut, type } from "../tokens";

const LOCKUP_W = 560;
const LOCKUP_H = LOCKUP_W * (1024 / 2984);

export const EndCard: React.FC = () => {
  const frame = useCurrentFrame();
  const opacity = interpolate(frame, [0, 22], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeOut,
  });
  const rise = interpolate(frame, [0, 30], [24, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeOut,
  });
  const urlOpacity = interpolate(frame, [30, 48], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeOut,
  });

  return (
    <>
      <Img
        src={staticFile("brand/devin-lockup-horizontal-black.png")}
        style={{
          position: "absolute",
          left: (1920 - LOCKUP_W) / 2,
          top: 420 - LOCKUP_H / 2,
          width: LOCKUP_W,
          height: LOCKUP_H,
          opacity,
          transform: `translateY(${rise}px)`,
        }}
      />
      <Headline size="h3" from={12} y={600} tone="muted">
        Build, run and test iOS apps in the cloud.
      </Headline>
      <div
        style={{
          position: "absolute",
          left: 0,
          right: 0,
          top: 690,
          textAlign: "center",
          fontFamily: mono,
          fontSize: type.sizes1080p.label,
          fontWeight: type.weights.medium,
          letterSpacing: type.tracking.caps,
          textTransform: "uppercase",
          color: color.ink,
          opacity: urlOpacity,
        }}
      >
        devin.ai
      </div>
    </>
  );
};
