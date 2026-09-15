import React from "react";
import { AbsoluteFill, Sequence } from "remotion";
import "./fonts";
import { color } from "./tokens";
import { scenes, sceneStarts } from "./scenes";
import { Hook } from "./scenes/Hook";
import { Problem } from "./scenes/Problem";
import { Build } from "./scenes/Build";
import { Live } from "./scenes/Live";
import { Tests } from "./scenes/Tests";
import { Screens } from "./scenes/Screens";
import { Outcome } from "./scenes/Outcome";
import { EndCard } from "./scenes/EndCard";

export const Main: React.FC = () => (
  <AbsoluteFill style={{ backgroundColor: color.paper }}>
    <Sequence from={sceneStarts.hook} durationInFrames={scenes.hook} name="Hook">
      <Hook />
    </Sequence>
    <Sequence from={sceneStarts.problem} durationInFrames={scenes.problem} name="Problem">
      <Problem />
    </Sequence>
    <Sequence from={sceneStarts.build} durationInFrames={scenes.build} name="Build + run">
      <Build />
    </Sequence>
    <Sequence from={sceneStarts.live} durationInFrames={scenes.live} name="Live Simulator">
      <Live />
    </Sequence>
    <Sequence from={sceneStarts.tests} durationInFrames={scenes.tests} name="Tests + PR">
      <Tests />
    </Sequence>
    <Sequence from={sceneStarts.screens} durationInFrames={scenes.screens} name="Screens">
      <Screens />
    </Sequence>
    <Sequence from={sceneStarts.outcome} durationInFrames={scenes.outcome} name="Outcome">
      <Outcome />
    </Sequence>
    <Sequence from={sceneStarts.end} durationInFrames={scenes.end} name="End card">
      <EndCard />
    </Sequence>
  </AbsoluteFill>
);
