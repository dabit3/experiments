import React from "react";
import { AbsoluteFill, Sequence } from "remotion";
import { Wipe } from "./components/Wipe";
import { SceneSpec, timeline } from "./scenes";
import { Context } from "./scenes/Context";
import { EndCard } from "./scenes/EndCard";
import { ChooseMac, FixAndShip, Matrix, Simulator } from "./scenes/Features";
import { Hook } from "./scenes/Hook";
import { Outcome } from "./scenes/Outcome";
import { color } from "./theme";

const components: Record<SceneSpec["id"], React.FC> = {
  hook: Hook,
  context: Context,
  chooseMac: ChooseMac,
  simulator: Simulator,
  fixAndShip: FixAndShip,
  matrix: Matrix,
  outcome: Outcome,
  end: EndCard,
};

export const Main: React.FC = () => (
  <AbsoluteFill style={{ background: color.white }}>
    {timeline.map((s, i) => {
      const Scene = components[s.id];
      return (
        <Sequence key={s.id} from={s.from} durationInFrames={s.duration} layout="none">
          <Wipe direction={s.wipe} enabled={i > 0}>
            <Scene />
          </Wipe>
        </Sequence>
      );
    })}
  </AbsoluteFill>
);
