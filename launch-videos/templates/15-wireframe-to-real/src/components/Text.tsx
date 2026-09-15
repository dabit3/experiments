import React from "react";
import { useCurrentFrame } from "remotion";
import { easeIn, easeOut, ms, prog } from "../anim";
import { color, FONT_MONO, FONT_SANS, type } from "../tokens";
import { SIZE } from "./Layout";

export const headlineStyle = (size: number): React.CSSProperties => ({
  fontFamily: FONT_SANS,
  fontSize: size,
  fontWeight: type.weights.medium,
  letterSpacing: type.tracking.heading,
  lineHeight: type.leading.heading,
  color: color.ink,
  margin: 0,
  whiteSpace: "pre-line",
});

export const bodyStyle = (size: number): React.CSSProperties => ({
  fontFamily: FONT_SANS,
  fontSize: size,
  fontWeight: type.weights.regular,
  letterSpacing: type.tracking.body,
  lineHeight: type.leading.body,
  color: color.gray500,
  margin: 0,
  whiteSpace: "pre-line",
});

export const labelStyle: React.CSSProperties = {
  fontFamily: FONT_MONO,
  fontSize: SIZE.label,
  fontWeight: type.weights.regular,
  letterSpacing: type.tracking.caps,
  textTransform: "uppercase",
  color: color.gray500,
  margin: 0,
};

type RiseProps = {
  /** frame (relative to the current Sequence) at which the text enters */
  from: number;
  /** frame at which the text has fully left; omit to keep it */
  to?: number;
  style?: React.CSSProperties;
  children: React.ReactNode;
  rise?: number;
};

/** Fade + 16px rise on entry (ease-out); fade + small drop on exit (ease-in). */
export const Rise: React.FC<RiseProps> = ({ from, to, style, children, rise = 16 }) => {
  const frame = useCurrentFrame();
  const inDur = ms(500);
  const outDur = ms(300);
  const a = prog(frame, from, inDur, easeOut);
  const b = to === undefined ? 0 : prog(frame, to - outDur, outDur, easeIn);
  const opacity = a * (1 - b);
  if (opacity <= 0) return null;
  const y = (1 - a) * rise + b * -8;
  return (
    <div style={{ ...style, opacity, transform: `translateY(${y}px)` }}>{children}</div>
  );
};
