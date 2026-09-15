import React from "react";
import { AbsoluteFill, Sequence } from "remotion";
import { Wallpaper } from "./components/Wallpaper";
import { scenes } from "./scenes";
import { ChoosePlatform } from "./scenes/ChoosePlatform";
import { Context } from "./scenes/Context";
import { EndCard } from "./scenes/EndCard";
import { Hook } from "./scenes/Hook";
import { Outcome } from "./scenes/Outcome";
import { Prompt } from "./scenes/Prompt";
import { PullRequest } from "./scenes/PullRequest";
import { Simulator } from "./scenes/Simulator";

const order: [keyof typeof scenes, React.FC][] = [
  ["hook", Hook],
  ["context", Context],
  ["choosePlatform", ChoosePlatform],
  ["prompt", Prompt],
  ["simulator", Simulator],
  ["pullRequest", PullRequest],
  ["outcome", Outcome],
  ["endCard", EndCard],
];

export const Main: React.FC = () => (
  <AbsoluteFill>
    <Wallpaper />
    {order.map(([id, Component]) => (
      <Sequence
        key={id}
        name={id}
        from={scenes[id].from}
        durationInFrames={scenes[id].duration}
        layout="none"
      >
        <Component />
      </Sequence>
    ))}
  </AbsoluteFill>
);
