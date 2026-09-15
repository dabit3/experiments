import React from "react";
import { AbsoluteFill, useCurrentFrame } from "remotion";
import type { CloseScene as CloseSceneProps, LaunchProps } from "../schema";
import { clamp, easeInOut, fitRect, lerpRect, MARGIN, overviewPlaneRect, slotAspect, WIDTH } from "../layout";
import { Grid, SheetMarks, TitleBlock, DimensionLine } from "../components/Drafting";
import { Plane } from "../components/Plane";
import { Headline, Logo, MaskReveal, Mono } from "../components/Text";

/**
 * The stages resolve into one completed result: the five planes slide along the baseline
 * into a single plane (the finished PR), then the outro line and CTA are revealed beneath it.
 */
export const CloseScene: React.FC<{ props: LaunchProps; scene: CloseSceneProps }> = ({ props, scene }) => {
  const frame = useCurrentFrame();
  const { brand, content, media, timing } = props;
  const n = content.stages.length;
  const resultSlot = media[scene.result];
  const matchIndex = content.stages.findIndex((s) => s.media === scene.result);
  const resultStage = matchIndex === -1 ? n - 1 : matchIndex;

  const target = fitRect(slotAspect(resultSlot), { x: (WIDTH - 1080) / 2, y: 140, w: 1080, h: 540 });
  const tMerge = clamp(frame, 4, 4 + timing.move + 14, easeInOut);
  const tLabel = clamp(frame, timing.move + 18, timing.move + 18 + timing.enter);
  const tOutro = clamp(frame, timing.move + 30, timing.move + 30 + timing.move, easeInOut);
  const tCta = clamp(frame, timing.move + 46, timing.move + 46 + timing.enter);

  return (
    <AbsoluteFill style={{ backgroundColor: brand.paper }}>
      <Grid brand={brand} opacity={1} />
      <SheetMarks brand={brand} opacity={1} />
      <div style={{ position: "absolute", left: MARGIN, top: MARGIN - 10 }}>
        <Logo brand={brand} height={48} />
      </div>

      {content.stages.map((stage, i) => {
        const isResult = stage.media === scene.result;
        const from = overviewPlaneRect(media[stage.media], i, n);
        const rect = lerpRect(from, target, tMerge);
        const fade = isResult ? 0 : 1 - clamp(tMerge, 0.55, 1);
        if (fade <= 0) {
          return null;
        }
        return (
          <Plane
            key={stage.id}
            slot={media[stage.media]}
            rect={rect}
            brand={brand}
            radius={6 + 6 * tMerge}
            opacity={fade}
            shadow={tMerge < 0.5}
          />
        );
      })}
      <Plane
        slot={resultSlot}
        rect={lerpRect(overviewPlaneRect(resultSlot, resultStage, n), target, tMerge)}
        brand={brand}
        radius={6 + 6 * tMerge}
      />

      <DimensionLine
        brand={brand}
        x1={target.x}
        x2={target.x + target.w}
        y={target.y + target.h + 34}
        label={`${content.stages.map((s) => s.label).join(" → ")}`}
        progress={tLabel}
      />

      <div style={{ position: "absolute", left: 0, top: target.y + target.h + 84, width: WIDTH, textAlign: "center" }}>
        <MaskReveal progress={tOutro}>
          <Headline brand={brand} text={content.outroLine} accent={content.outroAccent} size={76} />
        </MaskReveal>
      </div>

      <div
        style={{
          position: "absolute",
          left: 0,
          top: target.y + target.h + 200,
          width: WIDTH,
          display: "flex",
          justifyContent: "center",
          alignItems: "center",
          gap: 24,
          opacity: tCta,
          transform: `translateY(${(1 - tCta) * 10}px)`,
        }}
      >
        <div
          style={{
            background: brand.ink,
            color: brand.white,
            borderRadius: 2,
            padding: "0 26px",
            height: 58,
            display: "flex",
            alignItems: "center",
            fontFamily: brand.fontFamily,
            fontSize: 27,
            letterSpacing: -0.3,
          }}
        >
          {content.cta.label}
        </div>
        <Mono brand={brand} size={20} color={brand.inkMuted} style={{ textTransform: "none" }}>
          {content.cta.url}
        </Mono>
      </div>

      <TitleBlock brand={brand} content={content} opacity={1} stageLabel="Completed" />
    </AbsoluteFill>
  );
};
