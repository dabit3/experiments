import React, { useEffect, useState } from "react";
import { AbsoluteFill, Sequence, continueRender, delayRender } from "remotion";
import { scenes, timing } from "./scenes";
import { color, fontsReady } from "./theme";
import { Ticker } from "./components/Ticker";
import { Hook } from "./scenes/Hook";
import { Context } from "./scenes/Context";
import { FeaturePlatform } from "./scenes/FeaturePlatform";
import { FeatureSimulator } from "./scenes/FeatureSimulator";
import { FeatureBugToPr } from "./scenes/FeatureBugToPr";
import { FeatureMatrix } from "./scenes/FeatureMatrix";
import { Outcome } from "./scenes/Outcome";
import { EndCard } from "./scenes/EndCard";

const sceneComponents: Record<(typeof scenes)[number]["id"], React.FC> = {
  hook: Hook,
  context: Context,
  platform: FeaturePlatform,
  simulator: FeatureSimulator,
  bugToPr: FeatureBugToPr,
  matrix: FeatureMatrix,
  outcome: Outcome,
  end: EndCard,
};

export const Main: React.FC = () => {
  const [handle] = useState(() => delayRender("Loading fonts"));
  useEffect(() => {
    fontsReady.then(() => continueRender(handle));
  }, [handle]);

  const end = timing("end");

  return (
    <AbsoluteFill style={{ backgroundColor: color.paper }}>
      {scenes.map((s) => {
        const Scene = sceneComponents[s.id];
        return (
          <Sequence key={s.id} from={s.from} durationInFrames={s.duration} name={s.id}>
            <Scene />
          </Sequence>
        );
      })}
      <Ticker invertFrom={end.from} />
    </AbsoluteFill>
  );
};
