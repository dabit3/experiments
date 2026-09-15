import React from "react";
import { AbsoluteFill, Sequence, staticFile } from "remotion";
import type { CalculateMetadataFunction } from "remotion";
import "./fonts";
import type { LaunchProps } from "./schema";
import { FRAME_H, FRAME_W, SceneView } from "./Scenes";

export const totalFrames = (props: LaunchProps) =>
  props.scenes.reduce((sum, s) => sum + s.durationInFrames, 0);

export const calculateLaunchMetadata: CalculateMetadataFunction<LaunchProps> = ({ props }) => ({
  durationInFrames: totalFrames(props),
  width: FRAME_W,
  height: FRAME_H,
  fps: 30,
});

/** Optional licensed @font-face declarations (see README: "Using NB International Pro"). */
const FontFaces: React.FC<{ faces: LaunchProps["brand"]["customFontFaces"] }> = ({ faces }) => {
  if (faces.length === 0) {
    return null;
  }
  const css = faces
    .map(
      (f) =>
        `@font-face{font-family:${JSON.stringify(f.family)};font-weight:${f.weight};src:url(${JSON.stringify(
          staticFile(f.src),
        )}) format("woff2");font-display:block;}`,
    )
    .join("\n");
  return <style>{css}</style>;
};

export const Launch: React.FC<LaunchProps> = (props) => {
  let from = 0;
  const total = props.scenes.length;
  return (
    <AbsoluteFill style={{ background: props.brand.paper }}>
      <FontFaces faces={props.brand.customFontFaces} />
      {props.scenes.map((scene, i) => {
        const start = from;
        from += scene.durationInFrames;
        return (
          <Sequence
            key={scene.id}
            from={start}
            durationInFrames={scene.durationInFrames}
            name={scene.id}
          >
            <SceneView scene={scene} props={props} page={i + 1} total={total} />
          </Sequence>
        );
      })}
    </AbsoluteFill>
  );
};
