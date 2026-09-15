import React from 'react';
import {AbsoluteFill, Sequence, useCurrentFrame} from 'remotion';
import type {LaunchProps} from './schema';
import {frameState} from './timeline';
import {ProductFrame} from './components/ProductFrame';
import {Rail} from './components/Rail';
import {Lockup} from './components/Lockup';
import {DemoOverlay, OpenOverlay, OutroOverlay, ResultOverlay} from './components/Overlays';
import {easeOut, enterStyle} from './motion';
import {loadFonts} from './fonts';

loadFonts();

export const Launch: React.FC<LaunchProps> = (props) => {
  const frame = useCurrentFrame();
  const state = frameState(props, frame);
  const {brand, layout, motion} = props;
  const lockupT = easeOut(frame, 0, motion.entranceFrames);

  return (
    <AbsoluteFill style={{background: brand.paper, fontFamily: brand.fontFamily}}>
      <div
        style={{
          position: 'absolute',
          left: layout.margin,
          top: layout.margin - 4,
          ...enterStyle(lockupT, -12, 'y'),
        }}
      >
        <Lockup src={brand.logoLight} height={26} />
      </div>

      <ProductFrame props={props} state={state} frame={frame} />

      {state.spans.map((span, i) => {
        const geo = state.geos[i];
        const lead = i === 0 ? 0 : state.half;
        const common = {props, geo, lead, durationInFrames: span.scene.durationInFrames};
        const {scene} = span;
        let overlay: React.ReactNode;
        switch (scene.type) {
          case 'open':
            overlay = <OpenOverlay {...common} />;
            break;
          case 'demo':
            overlay = <DemoOverlay {...common} scene={scene} />;
            break;
          case 'result':
            overlay = <ResultOverlay {...common} scene={scene} />;
            break;
          case 'outro':
            overlay = <OutroOverlay {...common} scene={scene} />;
            break;
        }
        return (
          <Sequence
            key={scene.id}
            from={span.start}
            durationInFrames={scene.durationInFrames}
            layout="none"
          >
            {overlay}
          </Sequence>
        );
      })}

      <Rail props={props} progress={state.progress} introFrame={frame} />
    </AbsoluteFill>
  );
};
