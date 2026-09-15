import React from "react";
import { AbsoluteFill } from "remotion";
import type { Brand, Content, LowerThirdCue, MediaSlot } from "../schema";
import { Media } from "../components/Media";
import { ChapterMarker } from "../components/ChapterMarker";
import { LowerThird } from "../components/LowerThird";
import { SpeedBadge } from "../components/SpeedBadge";
import {
  fitMedia,
  LOWER_THIRD_GAP,
  stageBottom,
  stageHeight,
  stageTop,
  stageWidth,
} from "../layout";
import { WIDTH } from "../defaults";

type Props = {
  brand: Brand;
  content: Content;
  chapter: number;
  chapterTitle: string;
  slot: MediaSlot;
  lowerThirds: LowerThirdCue[];
  showSpeedBadge?: boolean;
  lowerThirdFrames: number;
};

/** One segment, one visible action: footage on the stage, captions below it. */
export const DemoScene: React.FC<Props> = ({
  brand,
  content,
  chapter,
  chapterTitle,
  slot,
  lowerThirds,
  showSpeedBadge,
  lowerThirdFrames,
}) => {
  const m = brand.safeMargin;
  const { width, height } = fitMedia(slot, stageWidth(brand), stageHeight(brand));
  const top = stageTop(brand) + (stageHeight(brand) - height) / 2;
  const left = (WIDTH - width) / 2;
  const ltLeft = Math.min(left, m + 0);
  return (
    <AbsoluteFill style={{ background: brand.paper }}>
      <ChapterMarker
        brand={brand}
        index={chapter}
        title={chapterTitle}
        featureName={content.featureName}
        left={m}
        right={m}
        top={m}
      />
      <div style={{ position: "absolute", left, top }}>
        <Media slot={slot} width={width} height={height} brand={brand} />
      </div>
      {showSpeedBadge ? (
        <SpeedBadge
          brand={brand}
          label={content.speedBadge}
          right={left}
          top={top + height + 20}
        />
      ) : null}
      {lowerThirds.map((cue) => (
        <LowerThird
          key={`${cue.caption}-${cue.from}`}
          brand={brand}
          text={content.captions[cue.caption] ?? ""}
          kicker={chapterTitle}
          from={cue.from}
          durationInFrames={cue.durationInFrames}
          transitionFrames={lowerThirdFrames}
          left={ltLeft}
          top={stageBottom(brand) + LOWER_THIRD_GAP}
          maxWidth={WIDTH - ltLeft - m}
        />
      ))}
    </AbsoluteFill>
  );
};
