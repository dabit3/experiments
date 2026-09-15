import React from "react";
import { Composition } from "remotion";
import { Main } from "./Main";
import { totalDurationInFrames } from "./scenes";
import { FPS, HEIGHT, WIDTH } from "./tokens";
import "./fonts";

export const Root: React.FC = () => (
  <Composition
    id="Main"
    component={Main}
    durationInFrames={totalDurationInFrames}
    fps={FPS}
    width={WIDTH}
    height={HEIGHT}
  />
);
