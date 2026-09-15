import React from "react";
import { AbsoluteFill, Sequence } from "remotion";
import type { LaunchProps } from "./schema";
import { Open } from "./scenes/Open";
import { Demo } from "./scenes/Demo";
import { Outro } from "./scenes/Outro";

export const totalDuration = (props: LaunchProps) =>
  props.scenes.reduce((sum, s) => sum + s.durationInFrames, 0);

export const Launch: React.FC<LaunchProps> = (props) => {
  const demoCount = props.scenes.filter((s) => s.type === "demo").length;
  let from = 0;
  let demoIndex = 0;

  return (
    <AbsoluteFill style={{ backgroundColor: props.brand.paper }}>
      {props.scenes.map((scene) => {
        const start = from;
        from += scene.durationInFrames;
        let node: React.ReactNode;
        if (scene.type === "open") {
          node = <Open props={props} durationInFrames={scene.durationInFrames} />;
        } else if (scene.type === "demo") {
          node = <Demo props={props} scene={scene} index={demoIndex} count={demoCount} />;
          demoIndex += 1;
        } else {
          node = <Outro props={props} />;
        }
        return (
          <Sequence
            key={scene.id}
            name={scene.id}
            from={start}
            durationInFrames={scene.durationInFrames}
          >
            {node}
          </Sequence>
        );
      })}
    </AbsoluteFill>
  );
};
