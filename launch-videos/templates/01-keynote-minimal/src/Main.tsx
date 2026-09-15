import React from "react";
import { AbsoluteFill, Sequence } from "remotion";
import { SceneFade } from "./components/Fade";
import { scenes, SceneId } from "./scenes";
import { Context } from "./scenes/Context";
import { EndCard } from "./scenes/EndCard";
import { FeatureMac } from "./scenes/FeatureMac";
import { FeatureMatrix } from "./scenes/FeatureMatrix";
import { FeaturePr } from "./scenes/FeaturePr";
import { FeatureSimulator } from "./scenes/FeatureSimulator";
import { Hook } from "./scenes/Hook";
import { Metrics } from "./scenes/Metrics";
import { color } from "./tokens";

const render = (id: SceneId, duration: number): React.ReactNode => {
  switch (id) {
    case "hook":
      return <Hook />;
    case "context":
      return <Context />;
    case "featureMac":
      return <FeatureMac duration={duration} />;
    case "featureSimulator":
      return <FeatureSimulator duration={duration} />;
    case "featurePr":
      return <FeaturePr duration={duration} />;
    case "featureMatrix":
      return <FeatureMatrix duration={duration} />;
    case "metrics":
      return <Metrics />;
    case "endCard":
      return <EndCard />;
  }
};

export const Main: React.FC = () => (
  <AbsoluteFill style={{ background: color.paper }}>
    {scenes.map(({ id, from, duration }, i) => (
      <Sequence key={id} from={from} durationInFrames={duration} name={id}>
        <SceneFade duration={duration} fadeIn={i === 0 ? 0 : undefined} fadeOut={i === scenes.length - 1 ? 24 : undefined}>
          {render(id, duration)}
        </SceneFade>
      </Sequence>
    ))}
  </AbsoluteFill>
);
