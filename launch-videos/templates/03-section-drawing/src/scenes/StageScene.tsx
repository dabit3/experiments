import React from "react";
import { AbsoluteFill, useCurrentFrame } from "remotion";
import type { LaunchProps, StageScene as StageSceneProps } from "../schema";
import {
  anchorPoint,
  captionColumn,
  clamp,
  easeInOut,
  fitRect,
  lerpRect,
  MARGIN,
  overviewPlaneRect,
  planeRegion,
  slotAspect,
  splitRects,
  type Rect,
} from "../layout";
import { Grid, SheetMarks, TitleBlock } from "../components/Drafting";
import { Plane } from "../components/Plane";
import { Leader } from "../components/Leader";
import { StageRail } from "../components/StageRail";
import { Body, Logo, MaskReveal, Mono } from "../components/Text";

export type StageExit = "slide" | "back";

/**
 * One stage brought forward: the plane(s) at reading size, the caption column beside them,
 * and leader lines from each caption to the exact UI region it describes.
 */
export const StageScene: React.FC<{
  props: LaunchProps;
  scene: StageSceneProps;
  exit: StageExit;
}> = ({ props, scene, exit }) => {
  const frame = useCurrentFrame();
  const { brand, content, media, timing } = props;
  const stage = content.stages[scene.stage];
  const side = scene.annotations[0]?.side ?? "right";
  const region = planeRegion(side);
  const column = captionColumn(side);

  const slots = scene.media.map((id) => media[id]);
  const rects: Rect[] =
    scene.layout === "split" && slots.length >= 2
      ? splitRects([slotAspect(slots[0]), slotAspect(slots[1])], region, side)
      : [fitRect(slotAspect(slots[0]), region)];

  const tIn = clamp(frame, 0, timing.move + 6, easeInOut);
  const tOut = clamp(frame, scene.durationInFrames - timing.move - 2, scene.durationInFrames - 2, easeInOut);
  const settled = tIn >= 1 && tOut <= 0;

  // Entry: lift the plane out of the overview diagram, or slide the section in from the right.
  const fromOverview = overviewPlaneRect(media[stage.media], scene.stage, content.stages.length);
  const SLIDE = 240;
  const shiftIn = scene.enter === "slide" ? (1 - tIn) * SLIDE : 0;
  const shiftOut = exit === "slide" ? -tOut * SLIDE : 0;
  // Sliding sections never drop to zero at the cut, so consecutive stages read as one continuous pan.
  const fadeIn = scene.enter === "slide" ? 0.35 + 0.65 * clamp(frame, 0, 10) : 1;
  const fadeOut = exit === "slide" ? 1 - 0.65 * clamp(frame, scene.durationInFrames - 10, scene.durationInFrames - 1) : 1;
  const planeOpacity = Math.min(fadeIn, fadeOut);

  const railOpacity = scene.enter === "forward" ? clamp(frame, timing.move - 4, timing.move + 10) : 1;
  const gridOpacity = scene.enter === "forward" ? 1 - tIn : exit === "back" ? tOut : 0;
  const chromeOut = exit === "back" ? 1 - tOut : 1;
  const captionOut = 1 - tOut;

  const mainRect =
    scene.enter === "forward" && tIn < 1
      ? lerpRect(fromOverview, rects[0], tIn)
      : exit === "back" && tOut > 0
        ? lerpRect(rects[0], fromOverview, tOut)
        : rects[0];

  const swapT = scene.swapAt !== undefined ? clamp(frame, scene.swapAt, scene.swapAt + timing.move, easeInOut) : 0;

  return (
    <AbsoluteFill style={{ backgroundColor: brand.paper }}>
      <Grid brand={brand} opacity={gridOpacity} />
      <SheetMarks brand={brand} opacity={1 - railOpacity} />
      <div style={{ position: "absolute", left: MARGIN, top: MARGIN - 10, opacity: 1 - railOpacity }}>
        <Logo brand={brand} height={48} />
      </div>
      <StageRail brand={brand} content={content} current={scene.stage} opacity={railOpacity * chromeOut} />

      {/* Other overview planes settle away while this one comes forward. */}
      {scene.enter === "forward" && tIn < 1
        ? content.stages.map((s, i) =>
            i === scene.stage ? null : (
              <div key={s.id} style={{ position: "absolute", left: 0, top: 0, opacity: 1 - tIn, transform: `translateY(${tIn * 24}px)` }}>
                <Plane slot={media[s.media]} rect={overviewPlaneRect(media[s.media], i, content.stages.length)} brand={brand} radius={6} />
              </div>
            ),
          )
        : null}

      <div style={{ position: "absolute", left: 0, top: 0, transform: `translateX(${shiftIn + shiftOut}px)`, opacity: planeOpacity }}>
        {scene.layout === "split" ? (
          rects.map((rect, i) => (
            <Plane key={scene.media[i]} slot={slots[i]} rect={rect} brand={brand} radius={12} speedBadge={content.speedBadge} />
          ))
        ) : (
          <div style={{ position: "absolute", left: mainRect.x, top: mainRect.y, width: mainRect.w, height: mainRect.h }}>
            <Plane slot={slots[0]} rect={{ x: 0, y: 0, w: mainRect.w, h: mainRect.h }} brand={brand} radius={tIn < 1 || tOut > 0 ? 6 + 6 * Math.min(tIn, 1 - tOut) : 12} speedBadge={content.speedBadge} />
            {slots[1] && scene.swapAt !== undefined && swapT > 0 ? (
              <MaskReveal progress={swapT} direction="down" style={{ position: "absolute", left: 0, top: 0, width: mainRect.w, height: mainRect.h }}>
                <Plane slot={slots[1]} rect={{ x: 0, y: 0, w: mainRect.w, h: mainRect.h }} brand={brand} radius={12} shadow={false} speedBadge={content.speedBadge} />
              </MaskReveal>
            ) : null}
          </div>
        )}
      </div>

      {/* Annotations: caption in the column, leader to the anchored UI region. */}
      {scene.annotations.map((a, k) => {
        const slotIndex = scene.media.indexOf(a.media);
        const rect = scene.layout === "split" ? rects[Math.max(0, slotIndex)] : mainRect;
        const slot = media[a.media];
        const to = anchorPoint(slot, rect, a.anchor);
        const boxTop = column.y + a.y * column.h;
        const textT = clamp(frame, a.startFrame, a.startFrame + timing.enter + 4);
        const leaderT = clamp(frame, a.startFrame + 6, a.startFrame + 6 + timing.leader, easeInOut) * (settled ? 1 : 0);
        const fromX = a.side === "right" ? column.x - 20 : column.x + column.w + 20;
        const from = { x: fromX, y: boxTop + 52 };
        const captionText = content.captions[a.caption] ?? "";
        const figure = `Fig. ${String(k + 1).padStart(2, "0")} · ${stage.label}`;
        return (
          <React.Fragment key={k}>
            <Leader brand={brand} from={from} to={to} side={a.side} progress={leaderT} />
            <div
              style={{
                position: "absolute",
                left: column.x,
                top: boxTop,
                width: column.w,
                opacity: textT * captionOut,
                transform: `translateY(${(1 - textT) * 10}px)`,
              }}
            >
              <Mono brand={brand} size={15} color={brand.inkSubtle}>
                {figure}
              </Mono>
              <div style={{ width: 64, height: 1, background: brand.ink, margin: "12px 0 16px" }} />
              <Body brand={brand} size={38}>
                {captionText}
              </Body>
            </div>
          </React.Fragment>
        );
      })}

      <TitleBlock brand={brand} content={content} opacity={chromeOut} stageLabel={`${String(scene.stage + 1).padStart(2, "0")} ${stage.label}`} />
    </AbsoluteFill>
  );
};
