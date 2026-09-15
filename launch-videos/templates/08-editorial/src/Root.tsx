import React from 'react';
import {Composition} from 'remotion';
import {Main} from './Main';
import {totalDuration} from './scenes';
import {FPS, HEIGHT, WIDTH} from './tokens';

export const Root: React.FC = () => (
  <Composition id="Main" component={Main} durationInFrames={totalDuration} fps={FPS} width={WIDTH} height={HEIGHT} />
);
