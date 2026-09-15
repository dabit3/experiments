import React from "react";
import { AbsoluteFill } from "remotion";
import { ms } from "../anim";
import { headlineStyle, Rise } from "../components/Text";
import { SIZE } from "../components/Layout";

const lines: { text: string; from: number; to: number }[] = [
  {
    text: "Before, iOS teams QA'd the app by hand\nor waited 20+ minutes on CI.",
    from: 0,
    to: ms(2700),
  },
  {
    text: "No coding agent could build, run\nand tap through an iPhone app.",
    from: ms(2800),
    to: ms(5600),
  },
];

export const Context: React.FC = () => (
  <AbsoluteFill style={{ justifyContent: "center", alignItems: "center", textAlign: "center" }}>
    {lines.map((l) => (
      <div key={l.text} style={{ position: "absolute" }}>
        <Rise from={l.from} to={l.to} style={headlineStyle(SIZE.headline)}>
          {l.text}
        </Rise>
      </div>
    ))}
  </AbsoluteFill>
);
