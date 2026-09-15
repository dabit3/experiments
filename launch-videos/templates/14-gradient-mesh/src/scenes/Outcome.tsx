import React from "react";
import { AbsoluteFill } from "remotion";
import { color, dur, sec } from "../tokens";
import { Headline, Label, SceneFade, useRise } from "../ui";

const metrics = [
  "Minutes, not 20+ minute CI round-trips.",
  "The only coding agent with a Mac cloud agent.",
  "Same security. No price increase.",
];

const Metric: React.FC<{ text: string; at: number; last: boolean }> = ({ text, at, last }) => {
  const rise = useRise(at, undefined, dur.slow);
  return (
    <div
      style={{
        padding: "34px 0",
        borderBottom: last ? "none" : `1px solid ${color.border}`,
        ...rise,
      }}
    >
      <Headline size="h2" align="left" maxWidth={1400}>
        {text}
      </Headline>
    </div>
  );
};

/** Outcome: three metric lines, staggered, separated by hairlines. */
export const Outcome: React.FC = () => {
  const label = useRise(0, undefined, dur.base);
  return (
    <SceneFade>
      <AbsoluteFill style={{ alignItems: "center", justifyContent: "center" }}>
        <div style={{ width: 1400 }}>
          <Label style={{ marginBottom: 20, ...label }}>Outcome</Label>
          {metrics.map((m, i) => (
            <Metric key={m} text={m} at={sec(0.3) + i * sec(0.9)} last={i === metrics.length - 1} />
          ))}
        </div>
      </AbsoluteFill>
    </SceneFade>
  );
};
