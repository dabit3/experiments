import React from "react";
import { AbsoluteFill, useCurrentFrame } from "remotion";
import { enter, lifetime } from "../components/anim";
import { color, font, leading, sizes, tracking, weight } from "../theme";

export const Hook: React.FC<{ duration: number }> = ({ duration }) => {
  const frame = useCurrentFrame();
  const p = enter(frame, 6, 28);
  const opacity = lifetime(frame, 6, duration, 28, 14);
  return (
    <AbsoluteFill style={{ justifyContent: "center", alignItems: "center" }}>
      <div
        style={{
          fontFamily: font.sans,
          fontSize: sizes.hero,
          fontWeight: weight.medium,
          letterSpacing: tracking.hero,
          lineHeight: leading.tight,
          color: color.ink,
          opacity,
          transform: `translateY(${(1 - p) * 24}px)`,
        }}
      >
        Devin now runs on Mac.
      </div>
    </AbsoluteFill>
  );
};
