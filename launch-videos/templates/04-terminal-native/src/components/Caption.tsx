import React from "react";
import { Easing, interpolate, useCurrentFrame } from "remotion";
import { color, easeIn, easeOut, font, radius, terminal, type } from "../tokens";
import { EXIT_FRAMES } from "./Pane";

/** Terminal-styled caption chip that narrates an expanded pane. */
export const Caption: React.FC<{
  label: string;
  lines: string[];
  at: number;
  exitAt: number;
}> = ({ label, lines, at, exitAt }) => {
  const frame = useCurrentFrame();
  const enter = interpolate(frame, [at, at + 16], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.bezier(...easeOut),
  });
  const exit = interpolate(frame, [exitAt, exitAt + EXIT_FRAMES], [1, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.bezier(...easeIn),
  });
  if (frame < at) return null;
  return (
    <div
      style={{
        position: "absolute",
        left: terminal.margin,
        bottom: terminal.margin,
        padding: "24px 32px 26px",
        backgroundColor: "rgba(8, 8, 8, 0.94)",
        border: `1px solid ${color.darkBorder}`,
        borderRadius: radius.md,
        opacity: enter * exit,
        maxWidth: 1100,
      }}
    >
      <div
        style={{
          fontFamily: font.mono,
          fontSize: type.sizes1080p.label,
          letterSpacing: type.tracking.caps,
          textTransform: "uppercase",
          color: color.gray400,
          marginBottom: 14,
        }}
      >
        <span style={{ color: color.accent, marginRight: 12 }}>▍</span>
        {label}
      </div>
      {lines.map((l) => (
        <div
          key={l}
          style={{
            fontFamily: font.sans,
            fontWeight: type.weights.medium,
            fontSize: 34,
            lineHeight: 1.25,
            letterSpacing: type.tracking.body,
            color: color.paper,
          }}
        >
          {l}
        </div>
      ))}
    </div>
  );
};
