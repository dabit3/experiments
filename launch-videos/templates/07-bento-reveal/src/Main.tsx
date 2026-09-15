import React from "react";
import { AbsoluteFill, Sequence } from "remotion";
import "./fonts";
import { scenes } from "./scenes";
import { color } from "./tokens";
import { Bento } from "./scenes/Bento";
import { Context } from "./scenes/Context";
import { EndCard } from "./scenes/EndCard";
import { Hook } from "./scenes/Hook";

export const Main: React.FC = () => (
  <AbsoluteFill style={{ background: color.paper }}>
    <Sequence name="Hook" from={scenes.hook.from} durationInFrames={scenes.hook.duration}>
      <Hook />
    </Sequence>
    <Sequence name="Context" from={scenes.context.from} durationInFrames={scenes.context.duration}>
      <Context />
    </Sequence>
    <Sequence name="Bento" from={scenes.bento.from} durationInFrames={scenes.bento.duration}>
      <Bento />
    </Sequence>
    <Sequence name="EndCard" from={scenes.endCard.from} durationInFrames={scenes.endCard.duration}>
      <EndCard />
    </Sequence>
  </AbsoluteFill>
);
