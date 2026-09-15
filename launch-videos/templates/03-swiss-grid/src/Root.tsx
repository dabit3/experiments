import React from "react";
import { Composition } from "remotion";
import { Main } from "./Main";
import { FPS, HEIGHT, TOTAL_FRAMES, WIDTH } from "./scenes";

export const RemotionRoot: React.FC = () => (
  <Composition
    id="Main"
    component={Main}
    durationInFrames={TOTAL_FRAMES}
    fps={FPS}
    width={WIDTH}
    height={HEIGHT}
  />
);
