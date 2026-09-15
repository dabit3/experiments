import React from "react";
import { Composition } from "remotion";
import { Main } from "./Main";
import { TOTAL_FRAMES } from "./scenes";
import { FPS, HEIGHT, WIDTH } from "./tokens";

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
