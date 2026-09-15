import React from "react";
import { AbsoluteFill, Sequence } from "remotion";
import type { LaunchProps } from "./schema";
import { TitleScene } from "./scenes/TitleScene";
import { OverviewScene } from "./scenes/OverviewScene";
import { StageScene, type StageExit } from "./scenes/StageScene";
import { CloseScene } from "./scenes/CloseScene";
import "./fonts";

export const totalDuration = (props: LaunchProps) =>
  props.scenes.reduce((sum, s) => sum + s.durationInFrames, 0);

export const Launch: React.FC<LaunchProps> = (props) => {
  let from = 0;
  return (
    <AbsoluteFill style={{ backgroundColor: props.brand.paper, fontFamily: props.brand.fontFamily }}>
      {props.scenes.map((scene, i) => {
        const start = from;
        from += scene.durationInFrames;
        const next = props.scenes[i + 1];
        const exit: StageExit = next?.kind === "close" ? "back" : "slide";
        return (
          <Sequence key={scene.id} from={start} durationInFrames={scene.durationInFrames} name={scene.id}>
            {scene.kind === "title" ? <TitleScene props={props} durationInFrames={scene.durationInFrames} /> : null}
            {scene.kind === "overview" ? <OverviewScene props={props} scene={scene} /> : null}
            {scene.kind === "stage" ? <StageScene props={props} scene={scene} exit={exit} /> : null}
            {scene.kind === "close" ? <CloseScene props={props} scene={scene} /> : null}
          </Sequence>
        );
      })}
    </AbsoluteFill>
  );
};
