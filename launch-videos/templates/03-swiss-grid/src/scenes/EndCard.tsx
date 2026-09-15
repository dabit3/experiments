import React from "react";
import { Img, staticFile, useCurrentFrame } from "remotion";
import { Scene } from "../components/Scene";
import { Line } from "../components/Text";
import { color, dur, FONT_MONO, grid, progress, type } from "../theme";

const LOCKUP_ASPECT = 2984 / 1024;
const LOCKUP_WIDTH = grid.span(4);
const LOCKUP_HEIGHT = LOCKUP_WIDTH / LOCKUP_ASPECT;

/** 08 — Devin lockup + one line + URL, flush-left on the grid. */
export const EndCard: React.FC<{ number: string }> = ({ number }) => {
  const frame = useCurrentFrame();
  const lockup = progress(frame, 4, dur.slow);

  return (
    <Scene number={number} title="Devin">
      <Img
        src={staticFile("brand/devin-lockup-horizontal-black.png")}
        style={{
          position: "absolute",
          left: grid.x(0),
          top: grid.rowMid - LOCKUP_HEIGHT - 8,
          width: LOCKUP_WIDTH,
          height: LOCKUP_HEIGHT,
          opacity: lockup,
          transform: `translateY(${(1 - lockup) * 16}px)`,
        }}
      />
      <div style={{ position: "absolute", left: grid.x(0), top: grid.rowMid + 40, width: grid.span(12) }}>
        <Line size="heading" enterAt={dur.base}>
          Build, run and test iOS apps in the cloud.
        </Line>
      </div>
      <div
        style={{
          position: "absolute",
          left: grid.x(0),
          top: grid.rowBottom - type.label,
          fontFamily: FONT_MONO,
          fontSize: type.label,
          fontWeight: 500,
          letterSpacing: type.trackingCaps,
          textTransform: "uppercase",
          lineHeight: 1,
          color: color.accent,
          opacity: progress(frame, dur.slow, dur.base),
        }}
      >
        devin.ai
      </div>
    </Scene>
  );
};
