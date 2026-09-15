import React from "react";
import { AbsoluteFill } from "remotion";
import { Accent, Headline, Label, useReveal } from "../components/Text";
import { color, light, MARGIN, size } from "../theme";

const rows: { at: number; text: React.ReactNode }[] = [
  { at: 10, text: <>Minutes, not <Accent>20+ minute</Accent> CI round-trips.</> },
  { at: 26, text: <>The only coding agent with a Mac cloud agent.</> },
  { at: 42, text: <>Same security. Same price as Linux.</> },
];

const Row: React.FC<{ at: number; children: React.ReactNode; last: boolean }> = ({
  at,
  children,
  last,
}) => {
  const rule = useReveal({ at: at - 4, rise: 0 });
  return (
    <div style={{ position: "relative", padding: "40px 0 40px 56px" }}>
      <div
        style={{
          position: "absolute",
          left: 0,
          top: 54,
          width: 14,
          height: 14,
          background: color.accent,
          opacity: rule.opacity,
        }}
      />
      <Headline palette={light} fontSize={size.h2} at={at}>
        {children}
      </Headline>
      {last ? null : (
        <div
          style={{
            position: "absolute",
            left: 0,
            right: 0,
            bottom: 0,
            height: 1,
            background: light.rule,
            opacity: rule.opacity,
          }}
        />
      )}
    </div>
  );
};

export const Outcome: React.FC = () => (
  <AbsoluteFill style={{ background: light.bg }}>
    <div style={{ position: "absolute", left: MARGIN, top: MARGIN }}>
      <Label palette={light} at={4}>
        What changes
      </Label>
    </div>
    <div
      style={{
        position: "absolute",
        left: MARGIN,
        right: MARGIN,
        top: 0,
        bottom: 0,
        display: "flex",
        flexDirection: "column",
        justifyContent: "center",
      }}
    >
      {rows.map((r, i) => (
        <Row key={i} at={r.at} last={i === rows.length - 1}>
          {r.text}
        </Row>
      ))}
    </div>
  </AbsoluteFill>
);
