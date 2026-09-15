import React from "react";
import { AbsoluteFill, Sequence } from "remotion";
import "./fonts";
import { Background } from "./components/Background";
import { DepthLayers } from "./components/DepthLayers";
import { scenes, SceneId } from "./scenes";
import { Hook } from "./scenes/Hook";
import { Context } from "./scenes/Context";
import { Feature } from "./scenes/Feature";
import { featureBugfix, featureMatrix, featureSession, featureSimulator } from "./scenes/features";
import { Outcome } from "./scenes/Outcome";
import { EndCard } from "./scenes/EndCard";

const isFeature = (id: SceneId | undefined) => id !== undefined && id.startsWith("feature");

const render = (id: SceneId, sceneFrom: number, prev: SceneId | undefined, next: SceneId | undefined): React.ReactNode => {
  const holdCard = isFeature(next);
  const continues = isFeature(prev);
  switch (id) {
    case "hook":
      return <Hook sceneFrom={sceneFrom} />;
    case "context":
      return <Context sceneFrom={sceneFrom} />;
    case "featureSession":
      return <Feature sceneFrom={sceneFrom} holdCard={holdCard} continues={continues} {...featureSession} />;
    case "featureSimulator":
      return <Feature sceneFrom={sceneFrom} holdCard={holdCard} continues={continues} {...featureSimulator} />;
    case "featureBugfix":
      return <Feature sceneFrom={sceneFrom} holdCard={holdCard} continues={continues} {...featureBugfix} />;
    case "featureMatrix":
      return <Feature sceneFrom={sceneFrom} holdCard={holdCard} continues={continues} {...featureMatrix} />;
    case "outcome":
      return <Outcome sceneFrom={sceneFrom} />;
    case "endCard":
      return <EndCard sceneFrom={sceneFrom} />;
  }
};

export const Main: React.FC = () => (
  <AbsoluteFill>
    <Background />
    <DepthLayers sceneFrom={0} />
    {scenes.map((s, i) => (
      <Sequence key={s.id} name={s.id} from={s.from} durationInFrames={s.durationInFrames}>
        {render(s.id, s.from, scenes[i - 1]?.id, scenes[i + 1]?.id)}
      </Sequence>
    ))}
  </AbsoluteFill>
);
