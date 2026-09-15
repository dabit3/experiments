import React from "react";
import { AbsoluteFill, useCurrentFrame } from "remotion";
import type { Brand, Content, MediaSlot } from "../schema";
import { Media } from "../components/Media";
import { ChapterMarker } from "../components/ChapterMarker";
import { enter } from "../motion";
import { fitMedia, MARKER_BAND, type } from "../layout";
import { HEIGHT, WIDTH } from "../defaults";

type Props = {
  brand: Brand;
  content: Content;
  slot: MediaSlot;
  label: string;
  enterFrames: number;
};

/** Large, undecorated product view straight after the title. */
export const HeroScene: React.FC<Props> = ({
  brand,
  content,
  slot,
  label,
  enterFrames,
}) => {
  const frame = useCurrentFrame();
  const m = brand.safeMargin;
  const labelBand = 64;
  const top = m + MARKER_BAND;
  const boxH = HEIGHT - top - m - labelBand;
  const { width, height } = fitMedia(slot, WIDTH - m * 2, boxH);
  const left = (WIDTH - width) / 2;
  const p = enter(frame, 6, enterFrames * 2);
  return (
    <AbsoluteFill style={{ background: brand.paper }}>
      <ChapterMarker
        brand={brand}
        title={content.headline}
        featureName={content.featureName}
        left={m}
        right={m}
        top={m}
      />
      <div
        style={{
          position: "absolute",
          left,
          top,
          opacity: p,
          transform: `translateY(${(1 - p) * 16}px)`,
        }}
      >
        <Media slot={slot} width={width} height={height} brand={brand} />
      </div>
      <div
        style={{
          position: "absolute",
          left,
          top: top + height + 22,
          ...type.label,
          fontFamily: brand.fontFamily,
          color: brand.inkMuted,
          opacity: enter(frame, 16, enterFrames),
        }}
      >
        {label}
      </div>
    </AbsoluteFill>
  );
};
