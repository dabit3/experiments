import React from "react";
import { AbsoluteFill, useCurrentFrame } from "remotion";
import type { Brand, Content, LowerThirdCue, MediaSlot } from "../schema";
import { Media } from "../components/Media";
import { ChapterMarker } from "../components/ChapterMarker";
import { LowerThird } from "../components/LowerThird";
import { SpeedBadge } from "../components/SpeedBadge";
import { enter } from "../motion";
import {
  fitMedia,
  LOWER_THIRD_GAP,
  stageBottom,
  stageHeight,
  stageTop,
  stageWidth,
  type,
} from "../layout";
import { WIDTH } from "../defaults";

type Props = {
  brand: Brand;
  content: Content;
  chapter: number;
  chapterTitle: string;
  slot: MediaSlot;
  evidence: MediaSlot;
  evidenceLabel: string;
  lowerThirds: LowerThirdCue[];
  showSpeedBadge?: boolean;
  enterFrames: number;
  lowerThirdFrames: number;
  /** Fraction of the frame width given to the primary footage (>= 0.55). */
  primaryFraction?: number;
  /** Frame at which the secondary panel slides in. */
  evidenceFrom?: number;
};

/** Primary footage plus an aligned secondary panel showing the delivered artifact. */
export const EvidenceScene: React.FC<Props> = ({
  brand,
  content,
  chapter,
  chapterTitle,
  slot,
  evidence,
  evidenceLabel,
  lowerThirds,
  showSpeedBadge,
  enterFrames,
  lowerThirdFrames,
  primaryFraction = 0.56,
  evidenceFrom = 24,
}) => {
  const frame = useCurrentFrame();
  const m = brand.safeMargin;
  const gap = 24;
  const primaryW = Math.round(WIDTH * primaryFraction);
  const primary = fitMedia(slot, primaryW, stageHeight(brand));
  const secondaryW = stageWidth(brand) - primary.width - gap;
  const secondary = fitMedia(evidence, secondaryW, stageHeight(brand) - 48);
  const top = stageTop(brand) + (stageHeight(brand) - primary.height) / 2;
  const secLeft = m + primary.width + gap;
  const p = enter(frame, evidenceFrom, enterFrames * 2);
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
      <div style={{ position: "absolute", left: m, top }}>
        <Media slot={slot} width={primary.width} height={primary.height} brand={brand} />
      </div>
      <div
        style={{
          position: "absolute",
          left: secLeft,
          top,
          width: secondaryW,
          opacity: p,
          transform: `translateX(${(1 - p) * 32}px)`,
        }}
      >
        <Media
          slot={evidence}
          width={secondary.width}
          height={secondary.height}
          brand={brand}
        />
        <div
          style={{
            marginTop: 16,
            display: "flex",
            alignItems: "center",
            gap: 10,
            ...type.eyebrow,
            fontFamily: brand.fontFamily,
            color: brand.inkMuted,
          }}
        >
          <span
            style={{
              width: 8,
              height: 8,
              borderRadius: 9999,
              background: brand.accent,
            }}
          />
          {evidenceLabel}
        </div>
      </div>
      {showSpeedBadge ? (
        <SpeedBadge
          brand={brand}
          label={content.speedBadge}
          right={WIDTH - m - primary.width}
          top={top + primary.height + 20}
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
          left={m}
          top={stageBottom(brand) + LOWER_THIRD_GAP}
          maxWidth={WIDTH - m * 2}
        />
      ))}
    </AbsoluteFill>
  );
};
