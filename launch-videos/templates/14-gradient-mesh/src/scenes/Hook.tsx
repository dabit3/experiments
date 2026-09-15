import React from "react";
import { AbsoluteFill } from "remotion";
import { dur } from "../tokens";
import { Headline, Label, SceneFade, useRise } from "../ui";

export const Hook: React.FC = () => {
  const label = useRise(0, undefined, dur.base);
  const title = useRise(6, undefined, dur.slow + 8);
  return (
    <SceneFade>
      <AbsoluteFill style={{ alignItems: "center", justifyContent: "center", gap: 28 }}>
        <Label style={label}>Devin on macOS · native iOS</Label>
        <Headline size="hero" style={title}>
          Devin now runs on Mac.
        </Headline>
      </AbsoluteFill>
    </SceneFade>
  );
};
