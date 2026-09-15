import React from "react";
import { Sequence } from "remotion";
import { Desk } from "./components/Desk";
import { SCENES } from "./scenes";
import { Hook } from "./scenes/Hook";
import { Context } from "./scenes/Context";
import { BuildRun } from "./scenes/BuildRun";
import { LiveSimulator } from "./scenes/LiveSimulator";
import { ReproFixPr } from "./scenes/ReproFixPr";
import { EveryScreen } from "./scenes/EveryScreen";
import { Outcome } from "./scenes/Outcome";
import { EndCard } from "./scenes/EndCard";

export const Main: React.FC = () => (
  <Desk>
    <Sequence {...SCENES.hook} name="Hook">
      <Hook />
    </Sequence>
    <Sequence {...SCENES.context} name="Context">
      <Context />
    </Sequence>
    <Sequence {...SCENES.buildRun} name="01 Build & run">
      <BuildRun />
    </Sequence>
    <Sequence {...SCENES.liveSimulator} name="02 Live Simulator">
      <LiveSimulator />
    </Sequence>
    <Sequence {...SCENES.reproFixPr} name="03 Repro, fix, PR">
      <ReproFixPr />
    </Sequence>
    <Sequence {...SCENES.everyScreen} name="04 Every screen">
      <EveryScreen />
    </Sequence>
    <Sequence {...SCENES.outcome} name="Outcome">
      <Outcome />
    </Sequence>
    <Sequence {...SCENES.endCard} name="End card">
      <EndCard />
    </Sequence>
  </Desk>
);
