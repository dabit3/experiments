import React from "react";
import { interpolate, useCurrentFrame } from "remotion";
import { Scene } from "../components/Scene";
import { Line } from "../components/Text";
import { color, dur, FONT_MONO, grid, progress, type } from "../theme";

const BEAT = 84;

const formatClock = (seconds: number) => {
  const m = Math.floor(seconds / 60);
  const s = Math.floor(seconds % 60);
  return `${String(m).padStart(2, "0")}:${String(s).padStart(2, "0")}`;
};

export const Context: React.FC<{ number: string }> = ({ number }) => {
  const frame = useCurrentFrame();

  // CI wait timer: linear count to 20+ minutes, then leaves with the first beat.
  const seconds = interpolate(frame, [8, BEAT - 6], [0, 20 * 60 + 14], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  const clockOpacity = progress(frame, 8, dur.base) * (1 - progress(frame, BEAT, dur.fast));

  return (
    <Scene number={number} title="Before">
      <div style={{ position: "absolute", left: grid.x(0), top: grid.rowMid - type.heading * type.leadingHeading, width: grid.span(7) }}>
        <Line size="heading" enterAt={4} exitAt={BEAT}>
          iOS teams QA'd the app by hand,
        </Line>
        <Line size="heading" enterAt={22} exitAt={BEAT} muted>
          or waited 20+ minutes for CI.
        </Line>
        <div style={{ position: "absolute", top: 0, left: 0, width: grid.span(9) }}>
          <Line size="heading" enterAt={BEAT + 12}>
            No coding agent could build, run
          </Line>
          <Line size="heading" enterAt={BEAT + 28} muted>
            and tap through an iPhone app on its own.
          </Line>
        </div>
      </div>

      <div
        style={{
          position: "absolute",
          left: grid.x(8),
          top: grid.rowMid - type.hero,
          fontFamily: FONT_MONO,
          fontSize: type.hero,
          fontWeight: 400,
          letterSpacing: "-0.02em",
          lineHeight: 1,
          color: color.ink,
          opacity: clockOpacity,
          fontVariantNumeric: "tabular-nums",
        }}
      >
        {formatClock(seconds)}
      </div>
      <div
        style={{
          position: "absolute",
          left: grid.x(8),
          top: grid.rowMid + 24,
          fontFamily: FONT_MONO,
          fontSize: type.label,
          fontWeight: 500,
          letterSpacing: type.trackingCaps,
          textTransform: "uppercase",
          color: color.gray500,
          opacity: clockOpacity,
        }}
      >
        CI round-trip
      </div>
    </Scene>
  );
};
