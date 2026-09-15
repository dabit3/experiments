import React from "react";
import { AbsoluteFill, Sequence, useVideoConfig } from "remotion";
import type { Brand, Content, DemoScene, Layout, MediaSlot } from "../schema";
import { Footage, type Box } from "../Footage";
import { type, useEnter } from "../Typography";

type Props = {
  scene: DemoScene;
  media: Record<string, MediaSlot>;
  brand: Brand;
  content: Content;
  layout: Layout;
};

const pad2 = (n: number) => String(n).padStart(2, "0");

const Caption: React.FC<{
  scene: DemoScene;
  brand: Brand;
  content: Content;
  layout: Layout;
  style: React.CSSProperties;
}> = ({ scene, brand, content, layout, style }) => {
  const enter = useEnter(0);
  const stageLabel = scene.stage === null ? null : content.stages[scene.stage];
  const caption = scene.caption === null ? null : content.captions[scene.caption];
  return (
    <div style={{ ...style, ...enter, color: brand.ink }}>
      {stageLabel || scene.speedLabel ? (
        <div
          style={{
            fontFamily: brand.monoFontFamily,
            fontSize: 16,
            lineHeight: "22px",
            letterSpacing: 0.2,
            color: brand.inkMuted,
            marginBottom: 10,
            display: "flex",
            alignItems: "center",
            gap: 14,
          }}
        >
          {stageLabel ? (
            <span>
              {scene.stage === null ? "" : pad2(scene.stage + 1)}
              <span style={{ color: brand.inkSubtle }}> · </span>
              {stageLabel}
            </span>
          ) : null}
          {scene.speedLabel ? <SpeedBadge label={scene.speedLabel} brand={brand} /> : null}
        </div>
      ) : null}
      {caption ? (
        <div
          style={{
            fontFamily: brand.fontFamily,
            fontSize: layout.captionSize,
            lineHeight: `${Math.round(layout.captionSize * 1.3)}px`,
            letterSpacing: -0.5,
            fontWeight: 400,
          }}
        >
          {caption}
        </div>
      ) : null}
    </div>
  );
};

// Shown next to the stage label whenever footage is sped up (brand.md: footage plays at
// 1x unless a speed badge is shown).
const SpeedBadge: React.FC<{ label: string; brand: Brand }> = ({ label, brand }) => (
  <span
    style={{
      fontFamily: brand.monoFontFamily,
      fontSize: 13,
      lineHeight: "18px",
      fontWeight: 500,
      color: brand.white,
      backgroundColor: brand.ink,
      borderRadius: 8,
      padding: "2px 8px",
    }}
  >
    {label}
  </span>
);

// One demo scene: a stage that holds the product footage (hard match cuts between
// shots), plus one caption in reserved space below or beside it.
export const Demo: React.FC<Props> = ({ scene, media, brand, content, layout }) => {
  const { width, height } = useVideoConfig();
  const side = scene.captionSide;

  const stageBox: Box =
    side === "bottom"
      ? {
          width: width - layout.marginX * 2,
          height:
            height - layout.marginTop - layout.marginBottom - layout.captionBand - layout.gap,
        }
      : {
          width: width - layout.marginX * 2 - layout.captionColumn - layout.gap,
          height: height - layout.marginTop - layout.marginBottom,
        };

  const shots = scene.shots.map((shot, i) => {
    const slot = media[shot.media];
    if (!slot) {
      throw new Error(`Scene "${scene.id}" references unknown media slot "${shot.media}"`);
    }
    const next = scene.shots[i + 1];
    const end = next ? next.at : scene.durationInFrames;
    return { shot, slot, end };
  });

  const captionStyle: React.CSSProperties =
    side === "bottom"
      ? {
          position: "absolute",
          left: layout.marginX,
          right: layout.marginX,
          top: height - layout.marginBottom - layout.captionBand,
          height: layout.captionBand,
          display: "flex",
          flexDirection: "column",
          justifyContent: "flex-end",
        }
      : {
          position: "absolute",
          right: layout.marginX,
          width: layout.captionColumn,
          top: layout.marginTop,
          bottom: layout.marginBottom,
          display: "flex",
          flexDirection: "column",
          justifyContent: "center",
        };

  return (
    <AbsoluteFill style={{ backgroundColor: brand.paper, ...type.body, fontFamily: brand.fontFamily }}>
      <div
        style={{
          position: "absolute",
          left: layout.marginX,
          top: layout.marginTop,
          width: stageBox.width,
          height: stageBox.height,
        }}
      >
        {shots.map(({ shot, slot, end }) => (
          <Sequence
            key={`${scene.id}-${shot.media}-${shot.at}`}
            from={shot.at}
            durationInFrames={end - shot.at}
            layout="none"
          >
            <div
              style={{
                position: "absolute",
                inset: 0,
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
              }}
            >
              <Footage
                slot={slot}
                box={stageBox}
                brand={brand}
                radius={layout.frameRadius}
                zoom={shot.zoom}
                durationInFrames={end - shot.at}
              />
            </div>
          </Sequence>
        ))}
      </div>
      <Caption scene={scene} brand={brand} content={content} layout={layout} style={captionStyle} />
    </AbsoluteFill>
  );
};
