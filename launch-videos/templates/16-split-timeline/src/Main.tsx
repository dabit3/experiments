import React from "react";
import { AbsoluteFill, Sequence } from "remotion";
import { Split, Timeline } from "./components/Chrome";
import { scenes } from "./scenes";
import { Build } from "./scenes/Build";
import { Context } from "./scenes/Context";
import { Drive } from "./scenes/Drive";
import { EndCard } from "./scenes/EndCard";
import { Fix } from "./scenes/Fix";
import { Hook } from "./scenes/Hook";
import { Outcome } from "./scenes/Outcome";
import { QA } from "./scenes/QA";
import { color } from "./theme";

const Scene: React.FC<{
  s: { from: number; duration: number };
  children: React.ReactNode;
}> = ({ s, children }) => (
  <Sequence from={s.from} durationInFrames={s.duration} layout="none">
    {children}
  </Sequence>
);

export const Main: React.FC = () => (
  <AbsoluteFill style={{ background: color.paper }}>
    <Scene s={scenes.hook}>
      <Hook duration={scenes.hook.duration} />
    </Scene>
    <Scene s={scenes.context}>
      <Context duration={scenes.context.duration} />
    </Scene>
    <Scene s={scenes.build}>
      <Build duration={scenes.build.duration} />
    </Scene>
    <Scene s={scenes.drive}>
      <Drive duration={scenes.drive.duration} />
    </Scene>
    <Scene s={scenes.fix}>
      <Fix duration={scenes.fix.duration} />
    </Scene>
    <Scene s={scenes.qa}>
      <QA duration={scenes.qa.duration} />
    </Scene>
    <Scene s={scenes.outcome}>
      <Outcome duration={scenes.outcome.duration} />
    </Scene>
    <Scene s={scenes.end}>
      <EndCard />
    </Scene>
    <Split />
    <Timeline />
  </AbsoluteFill>
);
