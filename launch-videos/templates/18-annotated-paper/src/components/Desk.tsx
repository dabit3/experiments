import React from "react";
import { AbsoluteFill } from "remotion";
import { color } from "../theme";

/** Neutral review surface the printed sheets sit on. */
export const Desk: React.FC<{ children: React.ReactNode }> = ({ children }) => (
  <AbsoluteFill
    style={{
      backgroundColor: color.surface,
      backgroundImage: `radial-gradient(ellipse at 50% 40%, ${color.paper} 0%, ${color.surface} 70%)`,
    }}
  >
    {children}
  </AbsoluteFill>
);
