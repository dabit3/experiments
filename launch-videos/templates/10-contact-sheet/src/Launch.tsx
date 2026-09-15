import React from "react";
import { AbsoluteFill, Sequence, useCurrentFrame } from "remotion";
import type { LaunchProps, SheetScene as SheetSceneProps } from "./schema";
import { ContactSheet } from "./ContactSheet";
import { ClipScene } from "./ClipScene";
import { OutroScene } from "./OutroScene";
import { clamp01, IndexFrame, indexFramesFromScenes } from "./layout";

const SheetScene: React.FC<{ scene: SheetSceneProps; props: LaunchProps; frames: IndexFrame[] }> = ({
  scene,
  props,
  frames,
}) => {
  const f = useCurrentFrame();
  const reveal = clamp01(f / Math.min(scene.selectAtFrame, 36));
  return (
    <ContactSheet
      brand={props.brand}
      content={props.content}
      media={props.media}
      sheet={props.sheet}
      frames={frames}
      selected={f >= scene.selectAtFrame ? 0 : null}
      viewedUpTo={0}
      reveal={reveal}
    />
  );
};

export const totalDuration = (props: LaunchProps) => props.scenes.reduce((sum, s) => sum + s.durationInFrames, 0);

export const Launch: React.FC<LaunchProps> = (props) => {
  const frames = indexFramesFromScenes(props.scenes);
  let from = 0;
  return (
    <AbsoluteFill style={{ backgroundColor: props.brand.paper }}>
      {props.scenes.map((scene) => {
        const start = from;
        from += scene.durationInFrames;
        return (
          <Sequence key={scene.id} name={scene.id} from={start} durationInFrames={scene.durationInFrames}>
            {scene.kind === "sheet" ? <SheetScene scene={scene} props={props} frames={frames} /> : null}
            {scene.kind === "clip" ? <ClipScene scene={scene} props={props} frames={frames} /> : null}
            {scene.kind === "outro" ? <OutroScene scene={scene} props={props} frames={frames} /> : null}
          </Sequence>
        );
      })}
    </AbsoluteFill>
  );
};
