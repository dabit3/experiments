import React from "react";
import { AbsoluteFill, Composition, Sequence } from "remotion";
import { timings, TOTAL_FRAMES, SceneId } from "./scenes";
import {
  Context,
  EndCard,
  FeatureFixPR,
  FeatureMacOS,
  FeatureMatrix,
  FeatureSimulator,
  Hook,
  Outcome,
} from "./SceneComponents";
import { color, fps } from "./tokens";

const SCENE_COMPONENTS: Record<SceneId, React.FC> = {
  hook: Hook,
  context: Context,
  "feature-macos": FeatureMacOS,
  "feature-simulator": FeatureSimulator,
  "feature-fix-pr": FeatureFixPR,
  "feature-matrix": FeatureMatrix,
  outcome: Outcome,
  end: EndCard,
};

export const Main: React.FC = () => {
  return (
    <AbsoluteFill style={{ backgroundColor: color.darkBg }}>
      {timings.map((t) => {
        const Scene = SCENE_COMPONENTS[t.id];
        return (
          <Sequence key={t.id} from={t.from} durationInFrames={t.durationInFrames} name={t.id}>
            <Scene />
          </Sequence>
        );
      })}
    </AbsoluteFill>
  );
};

export const RemotionRoot: React.FC = () => {
  return (
    <Composition
      id="Main"
      component={Main}
      durationInFrames={TOTAL_FRAMES}
      fps={fps}
      width={1920}
      height={1080}
    />
  );
};
