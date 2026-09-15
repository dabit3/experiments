import React from "react";

/** Eyebrow / index label: small, uppercase, positive tracking, mono. */
export const Label: React.FC<{
  text: string;
  x: number;
  y: number;
  color: string;
  fontFamily: string;
  opacity?: number;
  offsetY?: number;
  inline?: boolean;
}> = ({ text, x, y, color, fontFamily, opacity = 1, offsetY = 0, inline = false }) => (
  <div
    style={{
      position: inline ? "relative" : "absolute",
      left: inline ? undefined : x,
      top: inline ? undefined : y + offsetY,
      transform: inline ? `translateY(${offsetY}px)` : undefined,
      fontFamily,
      fontSize: 16,
      lineHeight: "20px",
      letterSpacing: "0.08em",
      textTransform: "uppercase",
      fontWeight: 500,
      color,
      opacity,
    }}
  >
    {text}
  </div>
);
