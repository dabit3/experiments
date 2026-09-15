import React from "react";
import { AbsoluteFill, Img, staticFile } from "remotion";
import { color } from "../tokens";
import { SceneFade, Rise, Fade } from "../components/SceneFade";
import { MonoLabel, Narration } from "../components/Text";

/** End card — lockup, one line, devin.ai */
export const EndCard: React.FC = () => (
  <SceneFade inFrames={14} outFrames={14}>
    <AbsoluteFill style={{ alignItems: "center", justifyContent: "center" }}>
      <Rise start={0} dur={24} distance={16}>
        <Img
          src={staticFile("brand/devin-lockup-horizontal-black.png")}
          style={{ width: 620, display: "block" }}
        />
      </Rise>
      <Rise start={16} dur={20} style={{ marginTop: 8 }}>
        <Narration style={{ textAlign: "center" }} color={color.ink}>
          Build, run and test iOS apps in the cloud.
        </Narration>
      </Rise>
      <Fade start={40} style={{ position: "absolute", bottom: 120 }}>
        <MonoLabel color={color.gray500}>devin.ai</MonoLabel>
      </Fade>
    </AbsoluteFill>
  </SceneFade>
);
