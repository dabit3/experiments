import React from "react";
import { useCurrentFrame } from "remotion";
import { SCENES } from "../scenes";
import { color, dur, FONT_MONO, grid, progress, type } from "../theme";

const TOTAL = String(SCENES.length).padStart(2, "0");

const labelStyle: React.CSSProperties = {
  fontFamily: FONT_MONO,
  fontSize: type.label,
  fontWeight: 500,
  letterSpacing: type.trackingCaps,
  textTransform: "uppercase",
  lineHeight: 1,
  color: color.gray500,
  whiteSpace: "nowrap",
};

/**
 * Anchors every scene: section number (accent) at the top-left, a one-column
 * rule beneath it, the section title, and the launch name at the top-right.
 */
export const SectionAnchor: React.FC<{ number: string; title: string }> = ({ number, title }) => {
  const frame = useCurrentFrame();
  const rule = progress(frame, 0, dur.slow);
  const text = progress(frame, dur.fast, dur.base);

  return (
    <>
      <div
        style={{
          position: "absolute",
          left: grid.x(0),
          top: grid.rowTop,
          display: "flex",
          alignItems: "baseline",
          gap: 16,
          opacity: text,
        }}
      >
        <span style={{ ...labelStyle, color: color.accent }}>{number}</span>
        <span style={labelStyle}>/ {TOTAL}</span>
        <span style={{ ...labelStyle, color: color.ink, marginLeft: grid.gutter }}>{title}</span>
      </div>
      <div
        style={{
          position: "absolute",
          left: grid.x(0),
          top: grid.rowTop + type.label + 16,
          width: grid.span(1) * rule,
          height: 2,
          background: color.accent,
        }}
      />
      <div
        style={{
          position: "absolute",
          right: grid.margin,
          top: grid.rowTop,
          opacity: text,
          ...labelStyle,
        }}
      >
        Devin on macOS
      </div>
    </>
  );
};
