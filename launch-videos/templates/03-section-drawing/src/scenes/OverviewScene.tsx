import React from "react";
import { AbsoluteFill, useCurrentFrame } from "remotion";
import type { LaunchProps, OverviewScene as OverviewSceneProps } from "../schema";
import {
  clamp,
  easeInOut,
  fitRect,
  HEIGHT,
  MARGIN,
  OVERVIEW_GAP_CLOSED,
  OVERVIEW_GAP_OPEN,
  OVERVIEW_ROW_H,
  OVERVIEW_ROW_Y,
  overviewBoxes,
  slotAspect,
  WIDTH,
} from "../layout";
import { Grid, SheetMarks, TitleBlock, DimensionLine } from "../components/Drafting";
import { Plane } from "../components/Plane";
import { Body, Eyebrow, Logo, Mono } from "../components/Text";

/**
 * The explanatory structure: the five stage planes drawn as one section, then separated so
 * the connections between them can be read. Diagram marks stay on the paper, not on the UI.
 */
export const OverviewScene: React.FC<{ props: LaunchProps; scene: OverviewSceneProps }> = ({
  props,
  scene,
}) => {
  const frame = useCurrentFrame();
  const { brand, content, media, timing } = props;
  const stages = content.stages;
  const n = stages.length;

  const tIn = clamp(frame, 0, timing.enter + 6);
  const tSep = clamp(frame, scene.separateAt, scene.separateAt + timing.move + 8, easeInOut);
  const gap = OVERVIEW_GAP_CLOSED + (OVERVIEW_GAP_OPEN - OVERVIEW_GAP_CLOSED) * tSep;
  const boxes = overviewBoxes(n, gap);
  const rects = stages.map((stage, i) =>
    fitRect(slotAspect(media[stage.media]), boxes[i], { x: "center", y: "end" }),
  );
  const labelsT = clamp(frame, scene.separateAt + timing.move, scene.separateAt + timing.move + timing.enter);
  const connT = (k: number) =>
    clamp(frame, scene.separateAt + timing.move + 4 + k * 5, scene.separateAt + timing.move + 4 + k * 5 + 12, easeInOut);
  const dimT = clamp(frame, scene.separateAt + timing.move + 30, scene.separateAt + timing.move + 30 + timing.move, easeInOut);
  const headingT = clamp(frame, 4, 4 + timing.enter);

  const rowBottom = OVERVIEW_ROW_Y + OVERVIEW_ROW_H;

  return (
    <AbsoluteFill style={{ backgroundColor: brand.paper }}>
      <Grid brand={brand} opacity={1} />
      <SheetMarks brand={brand} opacity={1} />
      <div style={{ position: "absolute", left: MARGIN, top: MARGIN - 10 }}>
        <Logo brand={brand} height={48} />
      </div>

      <div style={{ position: "absolute", left: MARGIN, top: 190, opacity: headingT }}>
        <Eyebrow brand={brand}>Section A–A · {content.featureName}</Eyebrow>
        <div
          style={{
            marginTop: 12,
            fontFamily: brand.fontFamily,
            fontWeight: 500,
            fontSize: 52,
            lineHeight: "58px",
            letterSpacing: -1.6,
            color: brand.ink,
          }}
        >
          {content.overviewTitle}
        </div>
      </div>

      {/* Connections drawn on the paper between separated planes. */}
      <svg style={{ position: "absolute", left: 0, top: 0 }} width={WIDTH} height={HEIGHT}>
        {content.connections.map(([a, b], k) => {
          const from = rects[a];
          const to = rects[b];
          if (!from || !to) {
            return null;
          }
          const y = rowBottom + 40;
          const x1 = from.x + from.w / 2;
          const x2 = to.x + to.w / 2;
          const p = connT(k) * tSep;
          const xEnd = x1 + (x2 - x1) * p;
          return (
            <g key={k} opacity={tSep}>
              <line x1={x1} y1={from.y + from.h} x2={x1} y2={y} stroke={brand.inkSubtle} strokeWidth={1} opacity={p > 0 ? 1 : 0} />
              <line x1={x1} y1={y} x2={xEnd} y2={y} stroke={brand.inkSubtle} strokeWidth={1} />
              {p >= 1 ? (
                <>
                  <line x1={x2} y1={y} x2={x2} y2={to.y + to.h} stroke={brand.inkSubtle} strokeWidth={1} />
                  <path
                    d={`M ${x2 - 5} ${to.y + to.h - 9} L ${x2} ${to.y + to.h - 2} L ${x2 + 5} ${to.y + to.h - 9}`}
                    fill="none"
                    stroke={brand.inkSubtle}
                    strokeWidth={1}
                  />
                </>
              ) : null}
            </g>
          );
        })}
      </svg>

      {stages.map((stage, i) => {
        const rect = rects[i];
        const delay = i * 3;
        const t = clamp(frame, delay, delay + timing.enter + 6);
        const rise = (1 - t) * 28;
        return (
          <div key={stage.id} style={{ position: "absolute", left: 0, top: 0, opacity: t, transform: `translateY(${rise}px)` }}>
            <Plane slot={media[stage.media]} rect={rect} brand={brand} radius={6} />
            <div
              style={{
                position: "absolute",
                left: boxes[i].x,
                top: rowBottom + 60,
                width: boxes[i].w,
                opacity: labelsT,
                transform: `translateY(${(1 - labelsT) * 8}px)`,
              }}
            >
              <Mono brand={brand} size={15} color={brand.inkSubtle}>
                {String(i + 1).padStart(2, "0")}
              </Mono>
              <Body brand={brand} size={30} style={{ marginTop: 4, fontWeight: 500 }}>
                {stage.label}
              </Body>
            </div>
          </div>
        );
      })}

      <DimensionLine
        brand={brand}
        x1={rects[0].x}
        x2={rects[n - 1].x + rects[n - 1].w}
        y={OVERVIEW_ROW_Y - 30}
        label={`${stages[0].label} → ${stages[n - 1].label}`}
        progress={dimT}
      />

      <div style={{ position: "absolute", left: MARGIN, bottom: MARGIN - 40, opacity: tIn }}>
        <Mono brand={brand} size={15}>
          Planes: product UI, 1:1 · Marks: explanatory
        </Mono>
      </div>
      <TitleBlock brand={brand} content={content} opacity={1} />
    </AbsoluteFill>
  );
};
