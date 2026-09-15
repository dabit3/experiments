import React from "react";
import { AbsoluteFill, Sequence, staticFile, useCurrentFrame } from "remotion";
import type { DemoScene, LaunchProps, MediaSlot } from "./schema";
import {
  HEIGHT,
  WIDTH,
  captionBox,
  easeInOut,
  fitPlate,
  mediaAspect,
  progress,
  scheduleScenes,
  stageBox,
} from "./lib";
import { Header, Paper } from "./components/Chrome";
import { Plate } from "./components/Plate";
import { TitleSheet } from "./components/TitleSheet";
import { Divider } from "./components/Divider";
import { CaptionStrip, type CaptionState } from "./components/CaptionStrip";
import { Outro } from "./components/Outro";
import "./fonts";

const getSlot = (media: LaunchProps["media"], name: string): MediaSlot => {
  const slot = media[name];
  if (!slot) {
    throw new Error(`Unknown media slot "${name}". Available: ${Object.keys(media).join(", ")}`);
  }
  return slot;
};

export const Launch: React.FC<LaunchProps> = ({
  brand,
  content,
  media,
  scenes,
  layout,
  motion,
  surface,
}) => {
  const frame = useCurrentFrame();
  const schedule = scheduleScenes(scenes);
  const stage = stageBox(layout);
  const strip = captionBox(layout);
  const half = Math.floor(motion.reveal / 2);

  // --- caption strip state -------------------------------------------------
  const captioned = schedule.filter(
    (s): s is typeof s & { scene: DemoScene } =>
      s.scene.kind === "demo" && s.scene.caption !== undefined,
  );
  const shown = captioned.filter((s) => s.start <= frame);
  const current = shown[shown.length - 1];
  const previous = shown[shown.length - 2];
  const demoScenes = schedule.filter((s) => s.scene.kind === "demo");
  const activeDemo = [...demoScenes].reverse().find((s) => s.start <= frame);
  const stageLabel = (() => {
    const withStage = [...demoScenes]
      .reverse()
      .find((s) => s.start <= frame && s.scene.kind === "demo" && s.scene.stage !== undefined);
    if (!withStage || withStage.scene.kind !== "demo" || withStage.scene.stage === undefined) {
      return undefined;
    }
    return content.stages[withStage.scene.stage - 1];
  })();
  const activeSlot =
    activeDemo && activeDemo.scene.kind === "demo" ? media[activeDemo.scene.media] : undefined;
  const firstDemo = demoScenes[0];
  const outro = schedule.find((s) => s.scene.kind === "outro");
  const demosEnd = outro ? outro.start : schedule[schedule.length - 1]?.end ?? 0;

  const captionState: CaptionState = {
    text: current ? content.captions[current.scene.caption! - 1] : undefined,
    ordinal: current ? shown.length : 0,
    total: captioned.length,
    changedAt: current ? current.start : (captioned[0]?.start ?? 0),
    previous: previous ? content.captions[previous.scene.caption! - 1] : undefined,
    previousOrdinal: previous ? shown.length - 1 : 0,
    stage: stageLabel,
    badge:
      activeSlot && activeSlot.kind === "video" && (activeSlot.playbackRate ?? 1) > 1
        ? content.speedBadge
        : undefined,
    progress: firstDemo
      ? progress(frame, firstDemo.start, demosEnd, (t) => t)
      : 0,
  };
  const dismiss = outro
    ? progress(frame, outro.start, outro.start + motion.layoutMove, easeInOut)
    : 0;

  return (
    <AbsoluteFill style={{ background: brand.paper }}>
      {brand.customFontFiles ? (
        <style>{`
          @font-face { font-family: "NB International Pro"; font-weight: 400; src: url("${staticFile(brand.customFontFiles.regular)}") format("woff2"); }
          @font-face { font-family: "NB International Pro"; font-weight: 500; src: url("${staticFile(brand.customFontFiles.medium)}") format("woff2"); }
        `}</style>
      ) : null}
      <Paper brand={brand} surface={surface} />
      <Header brand={brand} content={content} layout={layout} />

      {/* Stage: sheets slide in and out through slots just above and below it. */}
      <div
        style={{
          position: "absolute",
          left: 0,
          right: 0,
          top: stage.y - 20,
          height: stage.h + 40,
          overflow: "hidden",
        }}
      >
        <div
          style={{
            position: "absolute",
            left: 0,
            top: -(stage.y - 20),
            width: WIDTH,
            height: HEIGHT,
          }}
        >
          {schedule.map(({ scene, start, end }) => {
              if (scene.kind === "title") {
                const slot = getSlot(media, scene.media);
                const box = fitPlate(mediaAspect(slot), layout.platePadding, stage);
                return (
                  <Sequence
                    key={scene.id}
                    from={start}
                    durationInFrames={end - start}
                    layout="none"
                    name={scene.id}
                  >
                    <Sequence
                      from={Math.max(0, scene.durationInFrames - motion.titleExit - 2)}
                      layout="none"
                      name={`${scene.id}-media`}
                    >
                      <Plate box={box} slot={slot} brand={brand} layout={layout} surface={surface} />
                    </Sequence>
                    <TitleSceneLayer
                      scene={scene}
                      box={stage}
                      brand={brand}
                      content={content}
                      layout={layout}
                      surface={surface}
                      exitFrames={motion.titleExit}
                    />
                  </Sequence>
                );
              }
              if (scene.kind === "demo") {
                const slot = getSlot(media, scene.media);
                const box = fitPlate(mediaAspect(slot), layout.platePadding, stage);
                const dividerStart = Math.max(0, start - half);
                const shift = start - dividerStart;
                const label =
                  scene.stage !== undefined
                    ? `${String(scene.stage).padStart(2, "0")} — ${content.stages[scene.stage - 1] ?? ""}`
                    : undefined;
                return (
                  <Sequence
                    key={scene.id}
                    from={dividerStart}
                    durationInFrames={end - dividerStart}
                    layout="none"
                    name={scene.id}
                  >
                    <Sequence from={shift} layout="none" name={`${scene.id}-media`}>
                      <Plate box={box} slot={slot} brand={brand} layout={layout} surface={surface} />
                    </Sequence>
                    <DividerLayer
                      kind={scene.reveal}
                      offset={half - shift}
                      duration={motion.reveal}
                      box={stage}
                      brand={brand}
                      layout={layout}
                      surface={surface}
                      label={label}
                    />
                  </Sequence>
                );
              }
              return null;
            })}
        </div>
      </div>

      {outro && outro.scene.kind === "outro"
        ? (() => {
            const slot = getSlot(media, outro.scene.media);
            const fromBox = fitPlate(mediaAspect(slot), layout.platePadding, stage);
            return (
              <Sequence
                from={outro.start}
                durationInFrames={outro.end - outro.start}
                layout="none"
                name={outro.scene.id}
              >
                <OutroLayer
                  fromBox={fromBox}
                  stage={stage}
                  slot={slot}
                  brand={brand}
                  content={content}
                  layout={layout}
                  surface={surface}
                  moveFrames={motion.layoutMove}
                />
              </Sequence>
            );
          })()
        : null}

      <CaptionStrip
        frame={frame}
        box={strip}
        brand={brand}
        content={content}
        layout={layout}
        surface={surface}
        state={captionState}
        slideFrames={motion.caption}
        dismiss={dismiss}
      />
    </AbsoluteFill>
  );
};

// Thin wrappers so each layer reads the frame relative to its own Sequence.

const TitleSceneLayer: React.FC<Omit<React.ComponentProps<typeof TitleSheet>, "frame">> = (
  props,
) => {
  const frame = useCurrentFrame();
  return <TitleSheet {...props} frame={frame} />;
};

const DividerLayer: React.FC<
  Omit<React.ComponentProps<typeof Divider>, "frame"> & { offset: number }
> = ({ offset, ...props }) => {
  const frame = useCurrentFrame();
  return <Divider {...props} frame={frame + offset} />;
};

const OutroLayer: React.FC<Omit<React.ComponentProps<typeof Outro>, "frame">> = (props) => {
  const frame = useCurrentFrame();
  return <Outro {...props} frame={frame} />;
};
