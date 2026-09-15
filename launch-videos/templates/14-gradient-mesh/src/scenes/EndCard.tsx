import React from "react";
import { AbsoluteFill, Img, staticFile } from "remotion";
import { INTER } from "../fonts";
import { color, dur, sec, type } from "../tokens";
import { Label, SceneFade, useRise } from "../ui";

export const EndCard: React.FC = () => {
  const lockup = useRise(0, undefined, dur.slow + 6);
  const line = useRise(sec(0.5), undefined, dur.slow);
  const url = useRise(sec(0.9), undefined, dur.slow);
  return (
    <SceneFade>
      <AbsoluteFill style={{ alignItems: "center", justifyContent: "center", gap: 36 }}>
        <Img
          src={staticFile("brand/devin-lockup-horizontal-black.png")}
          style={{ width: 560, height: "auto", display: "block", ...lockup }}
        />
        <div
          style={{
            fontFamily: INTER,
            fontWeight: type.weights.regular,
            fontSize: type.sizes1080p.body,
            letterSpacing: type.tracking.body,
            color: color.gray500,
            ...line,
          }}
        >
          Build, run and test iOS apps in the cloud.
        </div>
        <Label style={{ color: color.ink, textTransform: "none", ...url }}>devin.ai</Label>
      </AbsoluteFill>
    </SceneFade>
  );
};
