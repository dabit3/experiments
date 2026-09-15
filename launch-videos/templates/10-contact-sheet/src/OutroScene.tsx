import React from "react";
import { AbsoluteFill, Img, interpolate, staticFile, useCurrentFrame } from "remotion";
import type { LaunchProps, OutroScene as OutroSceneProps } from "./schema";
import { ContactSheet } from "./ContactSheet";
import { MediaFrame } from "./MediaFrame";
import { cellRect, easeInOut, fade, HERO, IndexFrame, lerpRect, MARGIN, pad2 } from "./layout";
import { HEIGHT, WIDTH } from "./defaults";

type Props = {
  scene: OutroSceneProps;
  props: LaunchProps;
  frames: IndexFrame[];
};

const SELECT_HOLD = 12;

/** The final artifact is re-selected on the index and enlarged as the hero frame. */
export const OutroScene: React.FC<Props> = ({ scene, props, frames }) => {
  const f = useCurrentFrame();
  const { brand, media, content, sheet } = props;
  const slot = media[scene.media];
  const E = scene.expandFrames;

  const cell = cellRect(sheet, frames.length, scene.frameIndex);
  const grow = interpolate(f, [SELECT_HOLD, SELECT_HOLD + E], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeInOut,
  });
  const rect = lerpRect(cell, HERO, grow);
  const textIn = fade(f, SELECT_HOLD + E - 4, SELECT_HOLD + E + 10);
  const textShift = (1 - textIn) * 10;

  if (!slot) {
    return null;
  }

  const col = { left: HERO.x + HERO.w + 96, width: WIDTH - MARGIN - (HERO.x + HERO.w + 96) };

  return (
    <AbsoluteFill style={{ backgroundColor: brand.paper, fontFamily: brand.fontFamily }}>
      <ContactSheet
        brand={brand}
        content={content}
        media={media}
        sheet={sheet}
        frames={frames}
        selected={scene.frameIndex}
        viewedUpTo={frames.length}
        hideIndex={scene.frameIndex}
        opacity={1 - grow}
      />

      {/* Hero frame index, outside the footage. */}
      <div
        style={{
          position: "absolute",
          left: HERO.x,
          top: HERO.y + HERO.h + 24,
          opacity: textIn,
          fontFamily: brand.monoFontFamily,
          fontSize: 13,
          lineHeight: "20px",
          letterSpacing: 0.3,
          textTransform: "uppercase",
          color: brand.inkSubtle,
        }}
      >
        {pad2(scene.frameIndex + 1)} / {pad2(frames.length)} · {frames[scene.frameIndex]?.label}
      </div>

      {/* Copy column. */}
      <div
        style={{
          position: "absolute",
          left: col.left,
          width: col.width,
          top: HERO.y,
          height: HERO.h,
          display: "flex",
          flexDirection: "column",
          justifyContent: "space-between",
          opacity: textIn,
          transform: `translateY(${textShift}px)`,
        }}
      >
        <div>
          <div
            style={{
              fontFamily: brand.fontFamily,
              fontWeight: 500,
              fontSize: 14,
              lineHeight: "20px",
              letterSpacing: 0.4,
              textTransform: "uppercase",
              color: brand.inkMuted,
              marginBottom: 24,
            }}
          >
            {content.featureName}
          </div>
          <div
            style={{
              fontFamily: brand.fontFamily,
              fontWeight: 500,
              fontSize: 52,
              lineHeight: "58px",
              letterSpacing: -1.9,
              color: brand.ink,
            }}
          >
            {content.outroLine}
          </div>
          <div style={{ display: "flex", alignItems: "center", gap: 20, marginTop: 40 }}>
            <div
              style={{
                backgroundColor: brand.ink,
                color: brand.white,
                borderRadius: 2,
                height: 44,
                padding: "0 18px",
                display: "flex",
                alignItems: "center",
                fontFamily: brand.fontFamily,
                fontWeight: 500,
                fontSize: 18,
                letterSpacing: -0.2,
                whiteSpace: "nowrap",
              }}
            >
              {content.cta.label}
            </div>
            <div
              style={{
                fontFamily: brand.monoFontFamily,
                fontSize: 15,
                color: brand.inkMuted,
                whiteSpace: "nowrap",
              }}
            >
              {content.cta.url}
            </div>
          </div>
        </div>
        <Img src={staticFile(brand.logoLight)} style={{ height: 34, width: "auto", alignSelf: "flex-start" }} />
      </div>

      <div
        style={{
          position: "absolute",
          left: MARGIN,
          top: HEIGHT - MARGIN - 20,
          opacity: textIn,
          fontFamily: brand.monoFontFamily,
          fontSize: 13,
          lineHeight: "20px",
          color: brand.inkSubtle,
        }}
      >
        {sheet.metadata}
      </div>

      <div style={{ position: "absolute", left: rect.x, top: rect.y, width: rect.w, height: rect.h }}>
        <MediaFrame
          slot={slot}
          brand={brand}
          width={rect.w}
          height={rect.h}
          radius={interpolate(grow, [0, 1], [8, 16])}
          shadow={grow >= 1}
          still={{ frame: slot.thumbFrame ?? slot.startFrom ?? 0 }}
        />
      </div>
    </AbsoluteFill>
  );
};
