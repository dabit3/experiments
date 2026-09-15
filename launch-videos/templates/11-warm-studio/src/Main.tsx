import React from "react";
import { AbsoluteFill, Sequence } from "remotion";
import { scenes, type SceneId } from "./scenes";
import { color } from "./tokens";
import { Hook } from "./scenes/Hook";
import { Context } from "./scenes/Context";
import { FeatureBuild } from "./scenes/FeatureBuild";
import { FeatureSimulator } from "./scenes/FeatureSimulator";
import { FeatureFix } from "./scenes/FeatureFix";
import { FeatureMatrix } from "./scenes/FeatureMatrix";
import { Outcome } from "./scenes/Outcome";
import { EndCard } from "./scenes/EndCard";

const components: Record<SceneId, React.FC> = {
  hook: Hook,
  context: Context,
  "feature-build": FeatureBuild,
  "feature-simulator": FeatureSimulator,
  "feature-fix": FeatureFix,
  "feature-matrix": FeatureMatrix,
  outcome: Outcome,
  end: EndCard,
};

export const Main: React.FC = () => (
  <AbsoluteFill style={{ background: color.paper }}>
    {scenes.map((s) => {
      const Component = components[s.id];
      return (
        <Sequence key={s.id} name={s.id} from={s.from} durationInFrames={s.durationInFrames}>
          <Component />
        </Sequence>
      );
    })}
  </AbsoluteFill>
);
