import React from "react";
import { Composition } from "remotion";
import { Main } from "./Main";
import { FPS, totalFrames } from "./scenes";

export const Root: React.FC = () => (
  <Composition
    id="Main"
    component={Main}
    durationInFrames={totalFrames}
    fps={FPS}
    width={1920}
    height={1080}
  />
);
