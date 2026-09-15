import React from "react";
import { AbsoluteFill, useCurrentFrame } from "remotion";
import type { LaunchProps } from "../schema";
import { clamp, CONTENT, easeInOut, MARGIN } from "../layout";
import { Grid, SheetMarks, TitleBlock, DimensionLine } from "../components/Drafting";
import { Body, Eyebrow, Headline, Logo, MaskReveal } from "../components/Text";

export const TitleScene: React.FC<{ props: LaunchProps; durationInFrames: number }> = ({
  props,
  durationInFrames,
}) => {
  const frame = useCurrentFrame();
  const { brand, content, timing } = props;
  const t0 = clamp(frame, 0, timing.enter);
  const tHead = clamp(frame, 8, 8 + timing.move + 6, easeInOut);
  const tRule = clamp(frame, 26, 26 + timing.move, easeInOut);
  const tSub = clamp(frame, 36, 36 + timing.enter);
  const out = clamp(frame, durationInFrames - 14, durationInFrames - 2, easeInOut);

  const headTop = 380;
  const headlineWidth = 1560;

  return (
    <AbsoluteFill style={{ backgroundColor: brand.paper }}>
      <Grid brand={brand} opacity={1} />
      <SheetMarks brand={brand} opacity={t0} />
      <div style={{ position: "absolute", left: MARGIN, top: MARGIN - 10, opacity: t0 }}>
        <Logo brand={brand} height={48} />
      </div>
      <div style={{ position: "absolute", left: MARGIN, top: headTop - 64, opacity: t0 * (1 - out) }}>
        <Eyebrow brand={brand}>
          {content.eyebrow} · {content.featureName}
        </Eyebrow>
      </div>
      <div style={{ position: "absolute", left: MARGIN, top: headTop, width: headlineWidth, opacity: 1 - out }}>
        <MaskReveal progress={tHead}>
          <Headline brand={brand} text={content.headline} accent={content.headlineAccent} size={120} />
        </MaskReveal>
      </div>
      <DimensionLine
        brand={brand}
        x1={MARGIN}
        x2={MARGIN + headlineWidth}
        y={headTop + 172}
        progress={tRule * (1 - out)}
      />
      <div
        style={{
          position: "absolute",
          left: MARGIN,
          top: headTop + 210,
          width: 1200,
          opacity: tSub * (1 - out),
          transform: `translateY(${(1 - tSub) * 12}px)`,
        }}
      >
        <Body brand={brand} size={38} color={brand.inkMuted}>
          {content.subhead}
        </Body>
      </div>
      <div
        style={{
          position: "absolute",
          left: CONTENT.x,
          top: CONTENT.y + CONTENT.h - 1,
          width: CONTENT.w * tRule,
          height: 1,
          background: brand.line,
        }}
      />
      <TitleBlock brand={brand} content={content} opacity={tSub} />
    </AbsoluteFill>
  );
};
