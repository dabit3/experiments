import React from "react";
import { useCurrentFrame } from "remotion";
import { Scene } from "../components/Scene";
import { Line } from "../components/Text";
import { color, dur, FONT_MONO, grid, progress, type } from "../theme";

const CELLS = [
  { label: "Platform", text: "The only coding agent with a Mac cloud agent." },
  { label: "Security", text: "Same security as Linux and Windows VMs." },
  { label: "Price", text: "No price increase. Same as Linux cloud sessions." },
  { label: "Works on Mac", text: "Child sessions, Declarative Repo Setup, the API and automations." },
];

const STAGGER = 10;
const HEADLINE_TOP = 300;
const CELLS_TOP = 480;

/** 07 — four metric cells across the 12 columns, one rule each. */
export const Outcome: React.FC<{ number: string }> = ({ number }) => {
  const frame = useCurrentFrame();

  return (
    <Scene number={number} title="Outcome">
      <div style={{ position: "absolute", left: grid.x(0), top: HEADLINE_TOP, width: grid.span(12) }}>
        <Line size="heading" enterAt={4}>
          Minutes, not 20+ minute CI round-trips.
        </Line>
      </div>
      {CELLS.map((cell, i) => {
        const at = dur.base + i * STAGGER;
        const rule = progress(frame, at, dur.slow);
        return (
          <div
            key={cell.label}
            style={{ position: "absolute", left: grid.x(i * 3), top: CELLS_TOP, width: grid.span(3) }}
          >
            <div style={{ height: 1, width: `${rule * 100}%`, background: color.ink }} />
            <div
              style={{
                marginTop: 16,
                fontFamily: FONT_MONO,
                fontSize: type.label,
                fontWeight: 500,
                letterSpacing: type.trackingCaps,
                textTransform: "uppercase",
                color: color.accent,
                opacity: progress(frame, at + 6, dur.base),
              }}
            >
              {cell.label}
            </div>
            <Line size="text" enterAt={at + 10} style={{ marginTop: 20 }}>
              {cell.text}
            </Line>
          </div>
        );
      })}
    </Scene>
  );
};
