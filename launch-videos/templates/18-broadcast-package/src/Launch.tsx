import React from "react";
import { AbsoluteFill, Sequence, staticFile } from "remotion";
import type { LaunchProps, MediaSlot, Scene } from "./schema";
import "./fonts";
import { Wipe } from "./components/Wipe";
import { TitleScene } from "./scenes/TitleScene";
import { HeroScene } from "./scenes/HeroScene";
import { ChapterScene } from "./scenes/ChapterScene";
import { DemoScene } from "./scenes/DemoScene";
import { EvidenceScene } from "./scenes/EvidenceScene";
import { ClosingScene } from "./scenes/ClosingScene";

const requireSlot = (props: LaunchProps, key: string): MediaSlot => {
  const slot = props.media[key];
  if (!slot) {
    throw new Error(`Unknown media slot "${key}"`);
  }
  return slot;
};

const renderScene = (scene: Scene, props: LaunchProps): React.ReactNode => {
  const { brand, content, motion } = props;
  switch (scene.type) {
    case "title":
      return (
        <TitleScene brand={brand} content={content} enterFrames={motion.enterFrames} />
      );
    case "hero":
      return (
        <HeroScene
          brand={brand}
          content={content}
          slot={requireSlot(props, scene.media)}
          label={scene.label}
          enterFrames={motion.enterFrames}
        />
      );
    case "chapter":
      return (
        <ChapterScene
          brand={brand}
          content={content}
          index={scene.index}
          title={scene.title}
          enterFrames={motion.enterFrames}
        />
      );
    case "demo":
      return (
        <DemoScene
          brand={brand}
          content={content}
          chapter={scene.chapter}
          chapterTitle={scene.chapterTitle}
          slot={requireSlot(props, scene.media)}
          lowerThirds={scene.lowerThirds}
          showSpeedBadge={scene.showSpeedBadge}
          lowerThirdFrames={motion.lowerThirdFrames}
        />
      );
    case "evidence":
      return (
        <EvidenceScene
          brand={brand}
          content={content}
          chapter={scene.chapter}
          chapterTitle={scene.chapterTitle}
          slot={requireSlot(props, scene.media)}
          evidence={requireSlot(props, scene.evidence)}
          evidenceLabel={scene.evidenceLabel}
          lowerThirds={scene.lowerThirds}
          showSpeedBadge={scene.showSpeedBadge}
          enterFrames={motion.enterFrames}
          lowerThirdFrames={motion.lowerThirdFrames}
        />
      );
    case "closing":
      return (
        <ClosingScene brand={brand} content={content} enterFrames={motion.enterFrames} />
      );
    default:
      return null;
  }
};

/**
 * Scenes play back to back. Each scene after the first wipes in over the previous
 * one, which is held for `motion.wipeFrames` extra frames underneath.
 */
export const Launch: React.FC<LaunchProps> = (props) => {
  const { scenes, motion, brand } = props;
  let start = 0;
  return (
    <AbsoluteFill style={{ background: brand.paper, fontFamily: brand.fontFamily }}>
      {brand.fontFaceCss ? (
        <style>
          {brand.fontFaceCss.replace(/url\("([^"]+)"\)/g, (_, p: string) =>
            `url("${p.startsWith("http") ? p : staticFile(p)}")`,
          )}
        </style>
      ) : null}
      {scenes.map((scene, i) => {
        const from = start;
        start += scene.durationInFrames;
        const isLast = i === scenes.length - 1;
        const body = renderScene(scene, props);
        return (
          <Sequence
            key={scene.id}
            from={from}
            durationInFrames={scene.durationInFrames + (isLast ? 0 : motion.wipeFrames)}
            name={scene.id}
          >
            {i === 0 ? body : <Wipe durationInFrames={motion.wipeFrames}>{body}</Wipe>}
          </Sequence>
        );
      })}
    </AbsoluteFill>
  );
};
