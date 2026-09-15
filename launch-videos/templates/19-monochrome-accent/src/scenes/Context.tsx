import React from "react";
import { AbsoluteFill, interpolate, useCurrentFrame } from "remotion";
import { MONO } from "../fonts";
import { Accent, Headline, Label, useReveal } from "../components/Text";
import { dark, MARGIN, size, tracking } from "../theme";

const SWITCH = 96;

/** Mono CI timer that counts up to 20:00 while the "before" copy is on screen. */
const Timer: React.FC = () => {
  const frame = useCurrentFrame();
  const anim = useReveal({ at: 10, until: SWITCH - 6, rise: 12 });
  const secs = Math.round(
    interpolate(frame, [10, SWITCH - 10], [0, 20 * 60], {
      extrapolateLeft: "clamp",
      extrapolateRight: "clamp",
    }),
  );
  const mm = String(Math.floor(secs / 60)).padStart(2, "0");
  const ss = String(secs % 60).padStart(2, "0");
  return (
    <div
      style={{
        fontFamily: MONO,
        fontWeight: 400,
        fontSize: size.hero,
        letterSpacing: "-0.02em",
        color: dark.muted,
        fontVariantNumeric: "tabular-nums",
        ...anim,
      }}
    >
      {mm}:{ss}
    </div>
  );
};

export const Context: React.FC = () => (
  <AbsoluteFill style={{ background: dark.bg }}>
    <div style={{ position: "absolute", left: MARGIN, top: MARGIN }}>
      <Label palette={dark} at={4}>
        Before
      </Label>
    </div>
    <div
      style={{
        position: "absolute",
        left: MARGIN,
        width: 1180,
        top: 0,
        bottom: 0,
        display: "flex",
        flexDirection: "column",
        justifyContent: "center",
        gap: 20,
      }}
    >
      <div style={{ position: "relative" }}>
        <div style={{ display: "flex", flexDirection: "column", gap: 20 }}>
          <Headline palette={dark} at={6} until={SWITCH - 12}>
            iOS teams tested by hand.
          </Headline>
          <Headline palette={dark} at={22} until={SWITCH - 12} style={{ color: dark.muted }}>
            Or waited <Accent>20+ minutes</Accent> for CI.
          </Headline>
        </div>
        <div style={{ position: "absolute", top: 0, left: 0, right: 0 }}>
          <Headline palette={dark} at={SWITCH}>
            No coding agent could tap through an iPhone app.
          </Headline>
        </div>
      </div>
    </div>
    <div
      style={{
        position: "absolute",
        right: MARGIN,
        top: 0,
        bottom: 0,
        display: "flex",
        alignItems: "center",
        letterSpacing: tracking.heading,
      }}
    >
      <Timer />
    </div>
  </AbsoluteFill>
);
