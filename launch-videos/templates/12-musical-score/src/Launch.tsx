import React from "react";
import { AbsoluteFill, Audio, Img, Sequence, staticFile, useCurrentFrame } from "remotion";
import type { LaunchProps } from "./schema";
import { buildTimeline, progress } from "./score";
import { brandFontFaceCss } from "./fonts";
import { ScoreStrip } from "./components/ScoreStrip";
import { Stage } from "./components/Stage";
import { Intro } from "./components/Intro";
import { Outro } from "./components/Outro";

const STAGE_EXIT = 10;

export const Launch: React.FC<LaunchProps> = ({ brand, content, media, scenes, layout, sound }) => {
  const frame = useCurrentFrame();
  const timeline = buildTimeline(scenes);
  const outro = timeline.find((s) => s.kind === "outro");
  const headerIn = progress(frame, 0, 20);
  const headerOut = outro ? 1 - progress(frame, outro.from, 16) : 1;

  const accentSrc = sound.cueAccentSrc ? staticFile(sound.cueAccentSrc) : null;

  let stageNumber = 0;

  return (
    <AbsoluteFill style={{ background: brand.paper, fontFamily: brand.fontFamily }}>
      <style>{brandFontFaceCss}</style>

      <div
        style={{
          position: "absolute",
          left: layout.margin,
          right: layout.margin,
          top: 44,
          height: 28,
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          opacity: headerIn * headerOut,
        }}
      >
        <Img src={staticFile(brand.logoLight)} style={{ height: 26 }} />
        <div
          style={{
            fontFamily: brand.monoFontFamily,
            fontSize: 14,
            lineHeight: "20px",
            letterSpacing: 0.4,
            textTransform: "uppercase",
            color: brand.inkMuted,
          }}
        >
          {content.featureName}
        </div>
      </div>

      {timeline.map((scene) => {
        if (scene.kind === "stage") stageNumber += 1;
        return (
          <Sequence
            key={scene.id}
            from={scene.from}
            durationInFrames={scene.durationInFrames}
            layout="none"
          >
            {scene.kind === "intro" ? (
              <Intro
                brand={brand}
                content={content}
                layout={layout}
                durationInFrames={scene.durationInFrames}
              />
            ) : scene.kind === "outro" ? (
              <Outro brand={brand} content={content} layout={layout} />
            ) : (
              <Stage
                scene={scene}
                stageNumber={stageNumber}
                brand={brand}
                content={content}
                layout={layout}
                media={media}
                exitFrames={STAGE_EXIT}
              />
            )}
          </Sequence>
        );
      })}

      <ScoreStrip brand={brand} layout={layout} trackLabels={content.stages} timeline={timeline} />

      {sound.enabled && accentSrc
        ? timeline.flatMap((scene) =>
            (scene.cues ?? []).map((cue) => (
              <Sequence
                key={`${scene.id}-${cue.label}`}
                from={scene.from + cue.at}
                durationInFrames={30}
                layout="none"
              >
                <Audio src={accentSrc} volume={() => sound.volume} />
              </Sequence>
            )),
          )
        : null}
    </AbsoluteFill>
  );
};
