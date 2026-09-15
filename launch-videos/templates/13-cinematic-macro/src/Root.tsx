import React from "react";
import { Composition } from "remotion";
import { Main } from "./Main";
import { TOTAL_FRAMES } from "./scenes";
import { tokens } from "./tokens";

export const Root: React.FC = () => (
  <Composition
    id="Main"
    component={Main}
    durationInFrames={TOTAL_FRAMES}
    fps={tokens.video.fps}
    width={tokens.video.width}
    height={tokens.video.height}
  />
);
