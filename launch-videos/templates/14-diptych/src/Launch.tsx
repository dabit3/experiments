import React from "react";
import { AbsoluteFill, Sequence } from "remotion";
import type { LaunchProps, Scene } from "./schema";
import { TitleScene } from "./scenes/TitleScene";
import { PairScene } from "./scenes/PairScene";
import { ResultScene } from "./scenes/ResultScene";
import { OutroScene } from "./scenes/OutroScene";

export const totalDuration = (scenes: Scene[]) =>
  scenes.reduce((sum, s) => sum + s.durationInFrames, 0);

/** Action-panel ratio a scene ends on (used to hand the divider to the next scene). */
const endRatio = (scene: Scene | undefined, fallback: number) =>
  scene?.kind === "pair" ? scene.split.balanced : fallback;

const startRatio = (scene: Scene | undefined, fallback: number) =>
  scene?.kind === "pair" ? scene.split.active : fallback;

export const Launch: React.FC<LaunchProps> = (props) => {
  const { scenes, brand } = props;
  let from = 0;
  return (
    <AbsoluteFill style={{ backgroundColor: brand.paper }}>
      {scenes.map((scene, i) => {
        const prev = scenes[i - 1];
        const next = scenes[i + 1];
        const start = from;
        from += scene.durationInFrames;
        let node: React.ReactNode;
        switch (scene.kind) {
          case "title":
            node = (
              <TitleScene
                scene={scene}
                props={props}
                nextRatio={startRatio(next, 0.5)}
              />
            );
            break;
          case "pair":
            node = (
              <PairScene
                scene={scene}
                props={props}
                prevRatio={endRatio(prev, scene.split.active)}
                handOffResult={
                  next?.kind === "result" && next.media === scene.resultMedia
                }
              />
            );
            break;
          case "result":
            node = (
              <ResultScene
                scene={scene}
                props={props}
                prevRatio={endRatio(prev, 0.5)}
              />
            );
            break;
          case "outro":
            node = <OutroScene props={props} />;
            break;
        }
        return (
          <Sequence
            key={scene.id}
            from={start}
            durationInFrames={scene.durationInFrames}
            name={scene.id}
          >
            {node}
          </Sequence>
        );
      })}
    </AbsoluteFill>
  );
};
