import React from "react";
import { AbsoluteFill, Sequence } from "remotion";
import type { CalculateMetadataFunction } from "remotion";
import type { LaunchProps } from "./schema";
import { FontFaces } from "./fonts";
import { Statement } from "./scenes/Statement";
import { Demo } from "./scenes/Demo";
import { Outro } from "./scenes/Outro";

export const totalDuration = (scenes: LaunchProps["scenes"]) =>
  scenes.reduce((sum, s) => sum + s.durationInFrames, 0);

export const calculateLaunchMetadata: CalculateMetadataFunction<LaunchProps> = ({ props }) => ({
  durationInFrames: totalDuration(props.scenes),
});

// Scenes are hard-cut back to back, like an edited live demo: no transitions.
export const Launch: React.FC<LaunchProps> = ({ brand, content, media, scenes, layout }) => {
  let from = 0;
  return (
    <AbsoluteFill style={{ backgroundColor: brand.paper }}>
      <FontFaces faces={brand.fontFaces} />
      {scenes.map((scene) => {
        const start = from;
        from += scene.durationInFrames;
        return (
          <Sequence key={scene.id} from={start} durationInFrames={scene.durationInFrames}>
            {scene.kind === "statement" ? (
              <Statement brand={brand} content={content} layout={layout} />
            ) : scene.kind === "demo" ? (
              <Demo scene={scene} media={media} brand={brand} content={content} layout={layout} />
            ) : (
              <Outro brand={brand} content={content} layout={layout} />
            )}
          </Sequence>
        );
      })}
    </AbsoluteFill>
  );
};
