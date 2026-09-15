import React from "react";
import { AbsoluteFill, interpolate, useCurrentFrame } from "remotion";
import { Masthead } from "../components/Masthead";
import { color, ease, font, space, WIDTH } from "../theme";

const ITEMS = [
  "Minutes, not 20+ minute CI round-trips.",
  "The only coding agent with a Mac cloud agent.",
  "Same security as Linux and Windows VMs.",
  "Same price as Linux cloud sessions.",
];

export const Outcome: React.FC = () => {
  const frame = useCurrentFrame();
  return (
    <AbsoluteFill>
      <Masthead left="The outcome" right="Devin on macOS" />
      <div style={{ position: "absolute", left: space.margin, top: 236, width: WIDTH - space.margin * 2 }}>
        {ITEMS.map((item, i) => {
          const start = 6 + i * 12;
          const t = interpolate(frame, [start, start + 18], [0, 1], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
            easing: ease.out,
          });
          return (
            <div
              key={i}
              style={{
                display: "flex",
                alignItems: "center",
                gap: 48,
                height: 160,
                borderBottom: `2px solid ${color.ink}`,
                opacity: t,
                transform: `translateY(${(1 - t) * 24}px)`,
                boxSizing: "border-box",
              }}
            >
              <span
                style={{
                  fontFamily: font.mono,
                  fontSize: 22,
                  fontWeight: 500,
                  letterSpacing: font.tracking.caps,
                  color: color.accent,
                  width: 64,
                  flexShrink: 0,
                }}
              >
                0{i + 1}
              </span>
              <span
                style={{
                  fontFamily: font.sans,
                  fontWeight: font.weight.medium,
                  fontSize: 60,
                  letterSpacing: font.tracking.heading,
                  lineHeight: 1,
                  color: color.ink,
                  whiteSpace: "nowrap",
                }}
              >
                {item}
              </span>
            </div>
          );
        })}
      </div>
    </AbsoluteFill>
  );
};
