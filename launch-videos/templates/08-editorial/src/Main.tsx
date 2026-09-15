import React from 'react';
import {TransitionSeries, linearTiming} from '@remotion/transitions';
import {pageTurn} from './transitions/pageTurn';
import {sceneOrder, scenes, TURN, type SceneId} from './scenes';
import {easeInOut} from './tokens';
import {Hook} from './scenes/Hook';
import {Context} from './scenes/Context';
import {Choose} from './scenes/Choose';
import {Live} from './scenes/Live';
import {Fix} from './scenes/Fix';
import {Matrix} from './scenes/Matrix';
import {Outcome} from './scenes/Outcome';
import {End} from './scenes/End';

const components: Record<SceneId, React.FC> = {
  hook: Hook,
  context: Context,
  choose: Choose,
  live: Live,
  fix: Fix,
  matrix: Matrix,
  outcome: Outcome,
  end: End,
};

export const Main: React.FC = () => (
  <TransitionSeries>
    {sceneOrder.flatMap((id, i) => {
      const Scene = components[id];
      const nodes: React.ReactNode[] = [
        <TransitionSeries.Sequence key={id} durationInFrames={scenes[id].duration}>
          <Scene />
        </TransitionSeries.Sequence>,
      ];
      if (i < sceneOrder.length - 1) {
        nodes.push(
          <TransitionSeries.Transition
            key={`${id}-turn`}
            presentation={pageTurn()}
            timing={linearTiming({durationInFrames: TURN, easing: easeInOut})}
          />,
        );
      }
      return nodes;
    })}
  </TransitionSeries>
);
