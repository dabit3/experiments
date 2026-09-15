import React from "react";
import { Easing, interpolate, useCurrentFrame } from "remotion";
import { color, easeOut } from "../tokens";

type Point = { x: number; y: number };

/**
 * Tap indicators: an accent ring blooms at each normalized point (0–1 of the pane)
 * in turn. The screenshots already contain the real pointer, so this only marks
 * where Devin is tapping.
 */
export const TapOverlay: React.FC<{
  taps: Point[];
  at: number;
  every?: number;
}> = ({ taps, at, every = 34 }) => {
  const frame = useCurrentFrame();
  return (
    <>
      {taps.map((p, i) => {
        const start = at + i * every;
        const t = interpolate(frame, [start, start + 22], [0, 1], {
          extrapolateLeft: "clamp",
          extrapolateRight: "clamp",
          easing: Easing.bezier(...easeOut),
        });
        if (frame < start || t >= 1) return null;
        return (
          <div
            key={`${p.x}-${p.y}`}
            style={{
              position: "absolute",
              left: `${p.x * 100}%`,
              top: `${p.y * 100}%`,
              width: 56,
              height: 56,
              marginLeft: -28,
              marginTop: -28,
              borderRadius: 999,
              border: `3px solid ${color.accent}`,
              backgroundColor: `rgba(34, 0, 255, ${0.25 * (1 - t)})`,
              opacity: 1 - t,
              transform: `scale(${0.35 + t * 0.9})`,
            }}
          />
        );
      })}
    </>
  );
};
