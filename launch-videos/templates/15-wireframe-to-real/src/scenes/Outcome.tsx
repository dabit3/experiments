import React from "react";
import { AbsoluteFill } from "remotion";
import { ms } from "../anim";
import { SketchText } from "../components/SketchText";
import { headlineStyle } from "../components/Text";
import { type } from "../tokens";

const lines = [
  "Minutes, not 20+ minute CI round-trips.",
  "The only coding agent with a Mac cloud agent.",
  "Same security. Same price as Linux.",
];

export const Outcome: React.FC<{ duration: number }> = ({ duration }) => (
  <AbsoluteFill style={{ justifyContent: "center", alignItems: "center" }}>
    <div style={{ display: "flex", flexDirection: "column", alignItems: "flex-start", gap: 40 }}>
      {lines.map((text, i) => (
        <SketchText
          key={text}
          from={ms(100) + i * ms(450)}
          resolveAt={ms(800) + i * ms(450)}
          to={duration}
          mode="bar"
          seed={20 + i}
          style={headlineStyle(type.sizes1080p.h2)}
        >
          {text}
        </SketchText>
      ))}
    </div>
  </AbsoluteFill>
);
