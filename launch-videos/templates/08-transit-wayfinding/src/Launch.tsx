import React from "react";
import { AbsoluteFill, Sequence } from "remotion";
import type { LaunchProps } from "./schema";
import { OpenScene } from "./scenes/OpenScene";
import { StationScene } from "./scenes/StationScene";
import { LinkScene } from "./scenes/LinkScene";
import { OutroScene } from "./scenes/OutroScene";
import { licensedFontFace } from "./fonts";

export const totalDuration = (props: LaunchProps) => props.scenes.reduce((sum, s) => sum + s.durationInFrames, 0);

export const Launch: React.FC<LaunchProps> = (props) => {
  let from = 0;
  return (
    <AbsoluteFill style={{ background: props.brand.paper }}>
      <style>{licensedFontFace(props.brand)}</style>
      {props.scenes.map((scene) => {
        const start = from;
        from += scene.durationInFrames;
        let node: React.ReactNode;
        switch (scene.type) {
          case "open":
            node = <OpenScene props={props} durationInFrames={scene.durationInFrames} />;
            break;
          case "station":
            node = <StationScene props={props} scene={scene} />;
            break;
          case "link":
            node = <LinkScene props={props} scene={scene} />;
            break;
          case "outro":
            node = <OutroScene props={props} />;
            break;
        }
        return (
          <Sequence key={scene.id} name={scene.id} from={start} durationInFrames={scene.durationInFrames}>
            {node}
          </Sequence>
        );
      })}
    </AbsoluteFill>
  );
};
