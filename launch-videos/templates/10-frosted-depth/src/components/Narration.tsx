import React from "react";
import { useCurrentFrame } from "remotion";
import { color, fontSans, type } from "../tokens";
import { enter, exit } from "../lib/motion";

export type Line = {
  text: string;
  /** Frame (relative to the scene) the line appears. */
  from: number;
  /** Frame the line starts to leave. Omit to stay until the scene ends. */
  until?: number;
};

type Props = {
  lines: Line[];
  x: number;
  y: number;
  width: number;
  size?: number;
  align?: "left" | "center";
  tone?: "primary" | "secondary";
};

const IN = 18;
const OUT = 10;

/** One narration line at a time. Fade + 24px rise on entry, fade on exit. */
export const Narration: React.FC<Props> = ({ lines, x, y, width, size = type.sizes1080p.h3, align = "left", tone = "primary" }) => {
  const frame = useCurrentFrame();
  return (
    <div style={{ position: "absolute", left: x, top: y, width }}>
      {lines.map((line) => {
        const a = enter(frame, line.from, IN);
        const b = line.until === undefined ? 1 : exit(frame, line.until, OUT);
        const opacity = Math.min(a, b);
        if (opacity <= 0) return null;
        return (
          <div
            key={line.text}
            style={{
              position: "absolute",
              left: 0,
              top: 0,
              width,
              fontFamily: fontSans,
              fontWeight: type.weights.medium,
              fontSize: size,
              lineHeight: type.leading.heading,
              letterSpacing: type.tracking.heading,
              color: tone === "primary" ? color.offWhite : color.gray400,
              textAlign: align,
              opacity,
              transform: `translateY(${(1 - a) * 24}px)`,
              textWrap: "balance",
            }}
          >
            {line.text}
          </div>
        );
      })}
    </div>
  );
};
