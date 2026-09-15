import React from "react";
import { AbsoluteFill, Sequence } from "remotion";
import { GridGuides } from "./components/GridGuides";
import { SCENES, SceneId } from "./scenes";
import { Context } from "./scenes/Context";
import { EndCard } from "./scenes/EndCard";
import { FeatureFix } from "./scenes/FeatureFix";
import { FeatureMatrix } from "./scenes/FeatureMatrix";
import { FeatureRun } from "./scenes/FeatureRun";
import { FeatureWatch } from "./scenes/FeatureWatch";
import { Hook } from "./scenes/Hook";
import { Outcome } from "./scenes/Outcome";
import { color } from "./theme";

const COMPONENTS: Record<SceneId, React.FC<{ number: string }>> = {
  hook: Hook,
  context: Context,
  featureRun: FeatureRun,
  featureWatch: FeatureWatch,
  featureFix: FeatureFix,
  featureMatrix: FeatureMatrix,
  outcome: Outcome,
  endCard: EndCard,
};

export const Main: React.FC = () => {
  let from = 0;
  return (
    <AbsoluteFill style={{ background: color.paper }}>
      <GridGuides />
      {SCENES.map((scene) => {
        const Component = COMPONENTS[scene.id];
        const start = from;
        from += scene.durationInFrames;
        return (
          <Sequence key={scene.id} from={start} durationInFrames={scene.durationInFrames} name={`${scene.number} ${scene.id}`}>
            <Component number={scene.number} />
          </Sequence>
        );
      })}
    </AbsoluteFill>
  );
};
