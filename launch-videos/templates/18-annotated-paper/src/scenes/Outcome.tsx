import React from "react";
import { AbsoluteFill } from "remotion";
import { useProgress, useSceneFade } from "../anim";
import { Paper } from "../components/Paper";
import { Check } from "../components/Ink";
import { color, ease, font, sec, type } from "../theme";

const W = 1240;
const ROW = 104;
const LINES = [
  "Minutes, not 20+ minute CI round-trips.",
  "The only coding agent with a Mac cloud agent.",
  "Same security. Same price as Linux sessions.",
];

const Row: React.FC<{ text: string; index: number }> = ({ text, index }) => {
  const at = sec(0.5 + index * 0.75);
  const t = useProgress(at, sec(0.55), ease.out);
  return (
    <div style={{ position: "relative", height: ROW, display: "flex", alignItems: "center" }}>
      <div style={{ position: "absolute", left: 0, top: 0, width: 60, height: ROW }}>
        <Check at_={{ x: 30, y: ROW / 2 }} at={at + sec(0.25)} size={34} width={4.5} />
      </div>
      <div
        style={{
          marginLeft: 92,
          opacity: t,
          transform: `translateY(${(1 - t) * 14}px)`,
          fontFamily: font.sans,
          fontWeight: 500,
          fontSize: 46,
          letterSpacing: type.tracking.heading,
          lineHeight: 1.1,
          color: color.ink,
          whiteSpace: "nowrap",
        }}
      >
        {text}
      </div>
    </div>
  );
};

/** Outcome: the reviewer's sign-off list. */
export const Outcome: React.FC = () => {
  const fade = useSceneFade();
  return (
    <AbsoluteFill style={{ opacity: fade }}>
      <Paper x={(1920 - W) / 2} y={262} width={W} rotate={0.5} padding={64} caption="Review notes" captionRight="approved">
        <div
          style={{
            fontFamily: font.mono,
            fontSize: type.sizes1080p.label,
            letterSpacing: type.tracking.caps,
            textTransform: "uppercase",
            color: color.accent,
            marginBottom: 28,
            lineHeight: 1,
          }}
        >
          Outcome
        </div>
        {LINES.map((l, i) => (
          <Row key={l} text={l} index={i} />
        ))}
        <div style={{ height: 40 }} />
      </Paper>
    </AbsoluteFill>
  );
};
