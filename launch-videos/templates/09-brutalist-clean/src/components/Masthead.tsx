import React from "react";
import { color, font, RULE, space } from "../theme";

/**
 * Newspaper-style masthead: mono kicker left, index right, thick rule below.
 */
export const Masthead: React.FC<{ left: string; right: string; opacity?: number }> = ({
  left,
  right,
  opacity = 1,
}) => (
  <div
    style={{
      position: "absolute",
      left: space.margin,
      right: space.margin,
      top: space.safe,
      opacity,
    }}
  >
    <div
      style={{
        display: "flex",
        justifyContent: "space-between",
        alignItems: "baseline",
        fontFamily: font.mono,
        fontSize: font.size.label,
        fontWeight: 500,
        letterSpacing: font.tracking.caps,
        textTransform: "uppercase",
        color: color.ink,
        paddingBottom: 14,
      }}
    >
      <span>{left}</span>
      <span>{right}</span>
    </div>
    <div style={{ height: RULE, background: color.ink }} />
  </div>
);
