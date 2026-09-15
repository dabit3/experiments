import React from "react";
import { AbsoluteFill, Img, staticFile } from "remotion";
import { MONO } from "../fonts";
import { Body, useReveal } from "../components/Text";
import { color, dark, MARGIN, size, tracking } from "../theme";

const LOCKUP_W = 620;
const LOCKUP_ASPECT = 2984 / 1024;

export const EndCard: React.FC = () => {
  const lockup = useReveal({ at: 6, rise: 24 });
  const rule = useReveal({ at: 18, rise: 0 });
  const url = useReveal({ at: 30, rise: 10 });
  return (
    <AbsoluteFill style={{ background: dark.bg }}>
      <div
        style={{
          position: "absolute",
          inset: 0,
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          justifyContent: "center",
          gap: 36,
        }}
      >
        <Img
          src={staticFile("brand/devin-lockup-horizontal-white.png")}
          style={{ width: LOCKUP_W, height: LOCKUP_W / LOCKUP_ASPECT, display: "block", ...lockup }}
        />
        <div style={{ width: 72, height: 4, background: color.accent, opacity: rule.opacity }} />
        <Body palette={dark} at={22} style={{ color: dark.fg, fontSize: size.h3 }}>
          Build, run and test iOS apps in the cloud.
        </Body>
      </div>
      <div
        style={{
          position: "absolute",
          left: 0,
          right: 0,
          bottom: MARGIN,
          textAlign: "center",
          fontFamily: MONO,
          fontSize: size.label,
          letterSpacing: tracking.caps,
          textTransform: "uppercase",
          color: dark.muted,
          ...url,
        }}
      >
        devin.ai
      </div>
    </AbsoluteFill>
  );
};
