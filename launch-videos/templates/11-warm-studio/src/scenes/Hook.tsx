import React from "react";
import { AbsoluteFill, useCurrentFrame } from "remotion";
import { Scene } from "../components/Scene";
import { Headline, Label } from "../components/Text";
import { fadeIn, rise } from "../components/motion";
import { dur } from "../tokens";

export const Hook: React.FC = () => {
  const frame = useCurrentFrame();
  const labelAt = 4;
  const headAt = 12;
  return (
    <Scene>
      <AbsoluteFill style={{ justifyContent: "center", alignItems: "center" }}>
        <div style={{ textAlign: "center" }}>
          <Label
            style={{
              opacity: fadeIn(frame, labelAt, dur.slow),
              transform: `translateY(${rise(frame, labelAt)}px)`,
              marginBottom: 40,
            }}
          >
            New · Mac cloud agent
          </Label>
          <Headline
            size="hero"
            style={{
              opacity: fadeIn(frame, headAt, dur.slow),
              transform: `translateY(${rise(frame, headAt, dur.slow, 32)}px)`,
            }}
          >
            Devin now runs on Mac.
          </Headline>
        </div>
      </AbsoluteFill>
    </Scene>
  );
};
