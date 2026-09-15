import React from "react";
import { interpolate, useCurrentFrame } from "remotion";
import { useProgress } from "../anim";
import { color, ease, font, sec, type } from "../theme";

type NarrationProps = {
  x: number;
  y: number;
  width: number;
  /** Small mono index label above the headline, e.g. "01 — Build & run". */
  label?: string;
  lines: string[];
  at: number;
  /** Optional frame at which this block fades out (for swapping copy mid-scene). */
  until?: number;
  size?: number;
  align?: "left" | "center";
};

/** Declarative on-screen narration: Inter Medium, tight tracking, fade + rise. */
export const Narration: React.FC<NarrationProps> = ({
  x,
  y,
  width,
  label,
  lines,
  at,
  until,
  size = 48,
  align = "left",
}) => {
  const frame = useCurrentFrame();
  const enter = useProgress(at, sec(0.6), ease.out);
  const exit =
    until === undefined
      ? 1
      : interpolate(frame, [until - sec(0.3), until], [1, 0], {
          extrapolateLeft: "clamp",
          extrapolateRight: "clamp",
          easing: ease.in,
        });
  const opacity = Math.min(enter, exit);
  return (
    <div
      style={{
        position: "absolute",
        left: x,
        top: y,
        width,
        textAlign: align,
        opacity,
        transform: `translateY(${(1 - enter) * 18}px)`,
      }}
    >
      {label ? (
        <div
          style={{
            fontFamily: font.mono,
            fontSize: type.sizes1080p.label,
            letterSpacing: type.tracking.caps,
            textTransform: "uppercase",
            color: color.accent,
            marginBottom: 22,
            lineHeight: 1,
          }}
        >
          {label}
        </div>
      ) : null}
      <div
        style={{
          fontFamily: font.sans,
          fontWeight: 500,
          fontSize: size,
          letterSpacing: type.tracking.heading,
          lineHeight: type.leading.heading,
          color: color.ink,
        }}
      >
        {lines.map((line, i) => (
          <div key={i}>{line}</div>
        ))}
      </div>
    </div>
  );
};
