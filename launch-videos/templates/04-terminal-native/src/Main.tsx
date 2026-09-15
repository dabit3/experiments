import React from "react";
import { AbsoluteFill, Sequence } from "remotion";
import { color } from "./tokens";
import { scenes } from "./scenes";
import { Hook } from "./scenes/Hook";
import { Context } from "./scenes/Context";
import { Feature } from "./scenes/Feature";
import { Outcome } from "./scenes/Outcome";
import { EndCard } from "./scenes/EndCard";
import { features } from "./features";

const featureScenes = [scenes.buildRun, scenes.liveSimulator, scenes.fixShip, scenes.everyScreen];

export const Main: React.FC = () => {
  return (
    <AbsoluteFill style={{ backgroundColor: color.darkBg }}>
      <Sequence from={scenes.hook.from} durationInFrames={scenes.hook.duration} name="Hook">
        <Hook />
      </Sequence>
      <Sequence from={scenes.context.from} durationInFrames={scenes.context.duration} name="Context">
        <Context />
      </Sequence>
      {features.map((f, i) => (
        <Sequence
          key={f.command}
          from={featureScenes[i].from}
          durationInFrames={featureScenes[i].duration}
          name={f.label}
        >
          <Feature {...f} duration={featureScenes[i].duration} />
        </Sequence>
      ))}
      <Sequence from={scenes.outcome.from} durationInFrames={scenes.outcome.duration} name="Outcome">
        <Outcome history={features[features.length - 1].command} />
      </Sequence>
      <Sequence from={scenes.endCard.from} durationInFrames={scenes.endCard.duration} name="End card">
        <EndCard />
      </Sequence>
    </AbsoluteFill>
  );
};
