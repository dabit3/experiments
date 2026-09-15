import React from "react";
import { AbsoluteFill } from "remotion";
import { color } from "../tokens";

/** Soft desktop wallpaper: paper base with two very quiet gradient pools. */
export const Wallpaper: React.FC = () => (
  <AbsoluteFill style={{ backgroundColor: color.paper }}>
    <AbsoluteFill
      style={{
        background: `radial-gradient(60% 55% at 78% 18%, ${color.accentSoft} 0%, rgba(233,229,255,0) 100%)`,
      }}
    />
    <AbsoluteFill
      style={{
        background: `radial-gradient(55% 50% at 18% 90%, ${color.white} 0%, rgba(255,255,255,0) 100%)`,
      }}
    />
    <AbsoluteFill
      style={{
        background: `radial-gradient(70% 70% at 50% 50%, rgba(0,0,0,0) 55%, rgba(25,25,25,0.05) 100%)`,
      }}
    />
  </AbsoluteFill>
);
