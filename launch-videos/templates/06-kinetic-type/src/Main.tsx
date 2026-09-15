import React from "react";
import { AbsoluteFill, Sequence } from "remotion";
import { sceneFrames, sceneStart, SceneId } from "./scenes";
import { EndCard } from "./scenes/EndCard";
import { FeatureBuild } from "./scenes/FeatureBuild";
import { FeatureFix } from "./scenes/FeatureFix";
import { FeatureLive } from "./scenes/FeatureLive";
import { FeatureMatrix } from "./scenes/FeatureMatrix";
import { Hook } from "./scenes/Hook";
import { Outcome } from "./scenes/Outcome";
import { Problem } from "./scenes/Problem";
import { color } from "./tokens";

const SCENE_COMPONENTS: Record<SceneId, React.FC> = {
  hook: Hook,
  problem: Problem,
  "feature-build": FeatureBuild,
  "feature-live": FeatureLive,
  "feature-fix": FeatureFix,
  "feature-matrix": FeatureMatrix,
  outcome: Outcome,
  end: EndCard,
};

export const Main: React.FC = () => (
  <AbsoluteFill style={{ backgroundColor: color.darkBg }}>
    {(Object.keys(SCENE_COMPONENTS) as SceneId[]).map((id) => {
      const Scene = SCENE_COMPONENTS[id];
      return (
        <Sequence
          key={id}
          name={id}
          from={sceneStart(id)}
          durationInFrames={sceneFrames(id)}
          layout="none"
        >
          <Scene />
        </Sequence>
      );
    })}
  </AbsoluteFill>
);
