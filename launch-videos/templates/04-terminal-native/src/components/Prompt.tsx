import React from "react";
import { Easing, interpolate, useCurrentFrame } from "remotion";
import { color, easeOut, font, terminal } from "../tokens";
import { TYPING_CPS, typeFrames } from "../scenes";

const lineStyle: React.CSSProperties = {
  fontFamily: font.mono,
  fontSize: terminal.fontSize,
  lineHeight: `${terminal.lineHeight}px`,
  color: color.paper,
  whiteSpace: "pre",
  display: "flex",
  alignItems: "center",
};

export const Cursor: React.FC<{ blink: boolean }> = ({ blink }) => {
  const frame = useCurrentFrame();
  const on = blink ? Math.floor(frame / 16) % 2 === 0 : true;
  return (
    <span
      style={{
        display: "inline-block",
        width: 13,
        height: 28,
        marginLeft: 2,
        backgroundColor: color.paper,
        opacity: on ? 1 : 0,
        verticalAlign: "middle",
      }}
    />
  );
};

/** A `❯ command` line typed in at TYPING_CPS. The cursor blinks while idle and
 *  disappears at `submitAt` (the frame "Enter" is pressed). */
export const TypedCommand: React.FC<{
  text: string;
  at: number;
  submitAt: number;
  cps?: number;
}> = ({ text, at, submitAt, cps = TYPING_CPS }) => {
  const frame = useCurrentFrame();
  const total = typeFrames(text, cps);
  const shown = Math.max(0, Math.min(text.length, Math.floor(((frame - at) / total) * text.length)));
  const typing = frame >= at && shown < text.length;
  const submitted = frame >= submitAt;
  return (
    <div style={lineStyle}>
      <span style={{ color: color.accent, marginRight: 14 }}>❯</span>
      <span>{text.slice(0, shown)}</span>
      {submitted ? null : <Cursor blink={!typing} />}
    </div>
  );
};

/** A previously executed command, dimmed. */
export const HistoryLine: React.FC<{ text: string }> = ({ text }) => (
  <div style={{ ...lineStyle, color: color.gray500 }}>
    <span style={{ marginRight: 14 }}>❯</span>
    <span>{text}</span>
  </div>
);

export type Tone = "dim" | "text" | "ok" | "warn" | "err" | "accent";

const toneColor: Record<Tone, string> = {
  dim: color.gray500,
  text: color.paper,
  ok: color.success,
  warn: color.warning,
  err: color.danger,
  accent: color.accent,
};

/** One output line that fades in (ease-out) at `at`. Optionally dims at `dimAt`. */
export const OutputLine: React.FC<{
  at: number;
  tone?: Tone;
  prefix?: string;
  prefixTone?: Tone;
  dimAt?: number;
  size?: number;
  children: React.ReactNode;
}> = ({ at, tone = "text", prefix, prefixTone, dimAt, size, children }) => {
  const frame = useCurrentFrame();
  const opacity = interpolate(frame, [at, at + 14], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.bezier(...easeOut),
  });
  const dimmed =
    dimAt === undefined
      ? 0
      : interpolate(frame, [dimAt, dimAt + 14], [0, 1], {
          extrapolateLeft: "clamp",
          extrapolateRight: "clamp",
        });
  const c = dimmed > 0.5 ? color.gray500 : toneColor[tone];
  return (
    <div style={{ ...lineStyle, opacity: opacity * (1 - dimmed * 0.45), color: c, fontSize: size ?? terminal.fontSize }}>
      {prefix ? (
        <span style={{ color: dimmed > 0.5 ? color.gray500 : toneColor[prefixTone ?? tone], marginRight: 14 }}>
          {prefix}
        </span>
      ) : null}
      <span>{children}</span>
    </div>
  );
};

export const Blank: React.FC<{ h?: number }> = ({ h = terminal.lineHeight }) => <div style={{ height: h }} />;
