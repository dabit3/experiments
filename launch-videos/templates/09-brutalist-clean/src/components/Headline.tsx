import React from "react";
import { interpolate, useCurrentFrame, useVideoConfig } from "remotion";
import { color, ease, font } from "../theme";

type Props = {
  lines: string[];
  size?: number;
  /** frame (relative to scene) at which the first line starts entering */
  enterAt?: number;
  /** stagger between lines, frames */
  stagger?: number;
  /** frame (relative) at which the block starts fading out; omit for none */
  exitAt?: number;
  exitDuration?: number;
  style?: React.CSSProperties;
  /** color for the line at this index */
  accentLine?: number;
};

export const Headline: React.FC<Props> = ({
  lines,
  size = font.size.h1,
  enterAt = 0,
  stagger = 4,
  exitAt,
  exitDuration,
  style,
  accentLine,
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const enterDur = Math.round(fps * 0.6);
  const exitDur = exitDuration ?? Math.round(fps * 0.3);

  const exitOpacity =
    exitAt === undefined
      ? 1
      : interpolate(frame, [exitAt, exitAt + exitDur], [1, 0], {
          extrapolateLeft: "clamp",
          extrapolateRight: "clamp",
          easing: ease.in,
        });

  return (
    <div
      style={{
        fontFamily: font.sans,
        fontWeight: font.weight.medium,
        fontSize: size,
        lineHeight: font.leading.tight,
        letterSpacing: size >= 100 ? font.tracking.hero : font.tracking.heading,
        color: color.ink,
        opacity: exitOpacity,
        ...style,
      }}
    >
      {lines.map((line, i) => {
        const start = enterAt + i * stagger;
        const t = interpolate(frame, [start, start + enterDur], [0, 1], {
          extrapolateLeft: "clamp",
          extrapolateRight: "clamp",
          easing: ease.out,
        });
        return (
          <div
            key={i}
            style={{
              opacity: t,
              transform: `translateY(${(1 - t) * 28}px)`,
              color: accentLine === i ? color.accent : undefined,
              whiteSpace: "nowrap",
            }}
          >
            {line}
          </div>
        );
      })}
    </div>
  );
};
