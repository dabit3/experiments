import React from "react";
import { AbsoluteFill, useCurrentFrame } from "remotion";
import { easeIn, easeOut, fadeInOut, progress } from "../anim";
import { Cursor, cursorAt } from "../components/Cursor";
import { Screen, Window } from "../components/Window";
import { MONO, SANS } from "../fonts";
import { HANDOFF } from "../handoff";
import { color, type } from "../tokens";
import { MERGE } from "./PullRequest";

const LINES: { from: number; to: number; text: string }[] = [
  { from: 30, to: 84, text: "Minutes, not 20+ minute CI round-trips." },
  { from: 86, to: 140, text: "The only coding agent with a Mac cloud agent." },
  { from: 142, to: 192, text: "Same security. No price increase." },
];

/** 7. Outcome — the window slides away and the metrics take the stage, one at a time. */
export const Outcome: React.FC = () => {
  const frame = useCurrentFrame();
  const exit = progress(frame, 0, 28, easeIn);
  const cursor = cursorAt([{ frame: 0, ...MERGE }], frame);
  const label = fadeInOut(frame, 30, 192, 12, 8);
  return (
    <AbsoluteFill>
      <Window zoom={HANDOFF.prEnd} y={exit * 200} opacity={1 - exit}>
        <Screen src="devin-web-9" />
        <Cursor state={cursor} zoom={HANDOFF.prEnd.scale} />
      </Window>
      <div
        style={{
          position: "absolute",
          left: 0,
          right: 0,
          top: 436,
          textAlign: "center",
          fontFamily: MONO,
          fontSize: type.sizes1080p.label,
          fontWeight: 500,
          letterSpacing: type.tracking.caps,
          textTransform: "uppercase",
          color: color.gray500,
          opacity: label,
        }}
      >
        Why it matters
      </div>
      {LINES.map((line) => {
        if (frame < line.from || frame >= line.to) return null;
        const i = progress(frame, line.from, line.from + 14, easeOut);
        const o = 1 - progress(frame, line.to - 8, line.to, easeIn);
        return (
          <div
            key={line.text}
            style={{
              position: "absolute",
              left: 120,
              right: 120,
              top: 490,
              textAlign: "center",
              fontFamily: SANS,
              fontSize: type.sizes1080p.h2,
              fontWeight: 500,
              letterSpacing: type.tracking.heading,
              lineHeight: type.leading.heading,
              color: color.ink,
              opacity: Math.min(i, o),
              transform: `translateY(${(1 - i) * 14}px)`,
            }}
          >
            {line.text}
          </div>
        );
      })}
    </AbsoluteFill>
  );
};
