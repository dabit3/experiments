import React from "react";
import { AbsoluteFill, Easing, interpolate, useCurrentFrame } from "remotion";
import { TerminalWindow } from "../components/TerminalWindow";
import { Blank, HistoryLine, OutputLine, TypedCommand } from "../components/Prompt";
import { color, easeOut, font, terminal, type } from "../tokens";
import { typeFrames } from "../scenes";

export const OUTCOME_COMMAND = "devin status";

const rows: [string, string][] = [
  ["speed", "Minutes, not 20+ minute CI round-trips."],
  ["platform", "The only coding agent with a Mac cloud agent."],
  ["security", "Same as Linux and Windows VMs."],
  ["price", "No increase. Same as Linux cloud sessions."],
];

const Row: React.FC<{ at: number; label: string; value: string }> = ({ at, label, value }) => {
  const frame = useCurrentFrame();
  const opacity = interpolate(frame, [at, at + 14], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.bezier(...easeOut),
  });
  return (
    <div style={{ display: "flex", alignItems: "baseline", height: 56, opacity, fontFamily: font.mono }}>
      <span
        style={{
          width: 200,
          fontSize: type.sizes1080p.label,
          letterSpacing: type.tracking.caps,
          textTransform: "uppercase",
          color: color.gray400,
        }}
      >
        {label}
      </span>
      <span style={{ fontSize: 30, color: color.paper }}>{value}</span>
    </div>
  );
};

export const Outcome: React.FC<{ history: string }> = ({ history }) => {
  const typeAt = 6;
  const submitAt = typeAt + typeFrames(OUTCOME_COMMAND) + 12;
  const first = submitAt + 6;
  return (
    <AbsoluteFill>
      <TerminalWindow>
        <HistoryLine text={history} />
        <TypedCommand text={OUTCOME_COMMAND} at={typeAt} submitAt={submitAt} />
        <Blank h={terminal.lineHeight - 8} />
        {rows.map(([label, value], i) => (
          <Row key={label} at={first + i * 22} label={label} value={value} />
        ))}
        <Blank h={20} />
        <OutputLine at={first + rows.length * 22 + 14} prefix="✓" prefixTone="ok" tone="dim">
          macOS child sessions, Declarative Repo Setup, Devin API and automations all work on Mac.
        </OutputLine>
      </TerminalWindow>
    </AbsoluteFill>
  );
};
