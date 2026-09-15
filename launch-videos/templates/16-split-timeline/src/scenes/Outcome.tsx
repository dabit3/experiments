import React from "react";
import { AbsoluteFill, useCurrentFrame } from "remotion";
import { enter, lifetime, move } from "../components/anim";
import { MARGIN, WIDTH, color, font, leading, sizes, tracking, weight } from "../theme";

const CONTENT_W = WIDTH - MARGIN * 2;
const LABEL_W = 260;
const VALUE_W = 140;
const BAR_W = CONTENT_W - LABEL_W - VALUE_W;
const SWITCH = 96;

const Bar: React.FC<{
  label: string;
  value: string;
  fill: number;
  at: number;
  until: number;
  accent?: boolean;
}> = ({ label, value, fill, at, until, accent }) => {
  const frame = useCurrentFrame();
  const opacity = lifetime(frame, at, until, 20, 12);
  const grow = move(frame, at + 6, 44);
  const text: React.CSSProperties = {
    fontFamily: font.sans,
    fontSize: sizes.body,
    fontWeight: weight.regular,
    letterSpacing: tracking.body,
    color: accent ? color.ink : color.gray500,
    lineHeight: 1,
  };
  return (
    <div style={{ display: "flex", alignItems: "center", opacity, height: 40 }}>
      <div style={{ ...text, width: LABEL_W }}>{label}</div>
      <div style={{ width: BAR_W, height: 8, background: color.surface, borderRadius: 2 }}>
        <div
          style={{
            width: BAR_W * fill * grow,
            height: 8,
            borderRadius: 2,
            background: accent ? color.accent : color.gray400,
          }}
        />
      </div>
      <div
        style={{
          ...text,
          fontFamily: font.mono,
          fontWeight: weight.medium,
          width: VALUE_W,
          textAlign: "right",
        }}
      >
        {value}
      </div>
    </div>
  );
};

/** Outcome / metrics: 04:12 vs a 20+ minute CI round-trip, then the launch facts. */
export const Outcome: React.FC<{ duration: number }> = ({ duration }) => {
  const frame = useCurrentFrame();
  const headP = enter(frame, 0, 22);
  const headOpacity = lifetime(frame, 0, SWITCH, 22, 12);
  const facts = [
    "The only coding agent with a Mac cloud agent.",
    "Same security as Linux and Windows VMs.",
    "No price increase — same as Linux sessions.",
  ];
  return (
    <AbsoluteFill>
      <div style={{ position: "absolute", left: MARGIN, right: MARGIN, top: 300 }}>
        <div
          style={{
            fontFamily: font.sans,
            fontSize: sizes.h1,
            fontWeight: weight.medium,
            letterSpacing: tracking.heading,
            lineHeight: leading.heading,
            color: color.ink,
            opacity: headOpacity,
            transform: `translateY(${(1 - headP) * 18}px)`,
            marginBottom: 96,
          }}
        >
          Minutes, not 20+ minute CI round-trips.
        </div>
        <div style={{ display: "flex", flexDirection: "column", gap: 32 }}>
          <Bar label="Devin on macOS" value="04:12" fill={252 / 1200} at={18} until={SWITCH} accent />
          <Bar label="CI round-trip" value="20:00+" fill={1} at={26} until={SWITCH} />
        </div>
      </div>
      <div
        style={{
          position: "absolute",
          left: MARGIN,
          right: MARGIN,
          top: 300,
          display: "flex",
          flexDirection: "column",
          gap: 28,
        }}
      >
        {facts.map((t, i) => {
          const at = SWITCH + 8 + i * 22;
          const p = enter(frame, at, 24);
          const opacity = lifetime(frame, at, duration, 24, 12);
          return (
            <div
              key={t}
              style={{
                fontFamily: font.sans,
                fontSize: sizes.h2,
                fontWeight: weight.medium,
                letterSpacing: tracking.heading,
                lineHeight: leading.heading,
                color: i === 0 ? color.ink : color.gray500,
                opacity,
                transform: `translateY(${(1 - p) * 16}px)`,
              }}
            >
              {t}
            </div>
          );
        })}
      </div>
    </AbsoluteFill>
  );
};
