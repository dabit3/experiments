import React from "react";
import { AbsoluteFill, Sequence } from "remotion";
import type { LaunchProps } from "./schema";
import { TitleCard } from "./scenes/TitleCard";
import { Beat } from "./scenes/Beat";
import { EndCard } from "./scenes/EndCard";
import { getBrandFontFace } from "./fonts";

export const totalDuration = (scenes: LaunchProps["scenes"]) =>
  scenes.reduce((sum, s) => sum + s.durationInFrames, 0);

export const Launch: React.FC<LaunchProps> = (props) => {
  const { brand, content, media, scenes, timing, typography } = props;
  let cursor = 0;
  return (
    <AbsoluteFill style={{ backgroundColor: brand.paper }}>
      <style>{getBrandFontFace()}</style>
      {scenes.map((scene) => {
        const from = cursor;
        cursor += scene.durationInFrames;
        return (
          <Sequence
            key={scene.id}
            from={from}
            durationInFrames={scene.durationInFrames}
            name={scene.id}
          >
            {scene.kind === "title" ? (
              <TitleCard scene={scene} brand={brand} content={content} typography={typography} />
            ) : scene.kind === "beat" ? (
              <Beat
                scene={scene}
                brand={brand}
                content={content}
                media={media}
                timing={timing}
                typography={typography}
              />
            ) : (
              <EndCard scene={scene} brand={brand} content={content} typography={typography} />
            )}
          </Sequence>
        );
      })}
    </AbsoluteFill>
  );
};
