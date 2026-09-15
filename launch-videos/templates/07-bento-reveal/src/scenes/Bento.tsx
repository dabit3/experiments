import React from "react";
import { AbsoluteFill, interpolate, useCurrentFrame } from "remotion";
import { featureByTile, features, outcomes } from "../content";
import { FULL_RECT, lerpRect, tileOrder, tileRects, tileStagger, type Rect, type TileId } from "../layout";
import { bento, timing } from "../scenes";
import { color, easeIn, easeInOut, easeOut, HEIGHT, radius, shadow, WIDTH } from "../tokens";
import { Expanded } from "../components/Expanded";
import { Screenshot } from "../components/Screenshot";
import { BrandTile, CompactTile, OutcomeTile, compactFigureSize } from "../components/TileContent";

const clamp01 = (v: number) => Math.min(1, Math.max(0, v));

const BUILD_IN = 24;
const BUILD_SPREAD = 30;
const OUTCOME_FADE = 20;
const OUTCOME_STAGGER = 6;

type TileState = {
  rect: Rect;
  opacity: number;
  scale: number;
  cornerRadius: number;
  expandT: number; // 0 = in grid, 1 = full frame
  featureFrame: number | null; // feature-local frame if this tile is the active one
  outcomeT: number; // 0 = compact content, 1 = outcome content
  z: number;
};

const useTileState = (id: TileId, frame: number): TileState => {
  const base = tileRects[id];
  const state: TileState = {
    rect: base,
    opacity: 1,
    scale: 1,
    cornerRadius: radius.lg,
    expandT: 0,
    featureFrame: null,
    outcomeT: 0,
    z: 1,
  };

  // 1. Staggered build-in from the centre.
  const delay = tileStagger(id) * BUILD_SPREAD;
  const build = interpolate(frame, [delay, delay + BUILD_IN], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeOut,
  });
  state.opacity = build;
  state.scale = 0.94 + 0.06 * build;

  // 2. Feature moments: the active tile expands to full frame, others recede.
  const E = timing.featureExpand;
  features.forEach((f, i) => {
    const start = bento.featureStart(i);
    const ff = frame - start;
    if (ff < 0 || ff >= timing.feature) return;
    const growing = ff < E;
    const shrinking = ff >= timing.feature - E;
    const t = growing
      ? easeInOut(ff / E)
      : shrinking
        ? easeInOut((timing.feature - ff) / E)
        : 1;
    if (f.tile === id) {
      state.expandT = t;
      state.rect = lerpRect(base, FULL_RECT, t);
      state.cornerRadius = radius.lg * (1 - t);
      state.featureFrame = ff;
      state.z = 10;
    } else {
      const fadeLen = E * 0.6;
      const recede = growing
        ? easeIn(clamp01(ff / fadeLen))
        : shrinking
          ? 1 - easeOut(clamp01((ff - (timing.feature - fadeLen)) / fadeLen))
          : 1;
      state.opacity *= 1 - recede;
      state.scale *= 1 - 0.03 * recede;
    }
  });

  // 3. Outcome flip: compact content cross-fades to the outcome statement.
  const outcomeIndex = tileOrder.indexOf(id);
  const flipStart = bento.outcomesStart + outcomeIndex * OUTCOME_STAGGER;
  state.outcomeT = interpolate(frame, [flipStart, flipStart + OUTCOME_FADE], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeInOut,
  });

  // 4. Brand tile grows into the end card; the rest of the grid fades away.
  const bf = frame - bento.brandExpandStart;
  if (bf >= 0) {
    const t = easeInOut(clamp01(bf / timing.brandExpand));
    if (id === "brand") {
      state.rect = lerpRect(base, FULL_RECT, t);
      state.cornerRadius = radius.lg * (1 - t);
      state.z = 10;
    } else {
      const fade = easeIn(clamp01(bf / (timing.brandExpand * 0.6)));
      state.opacity *= 1 - fade;
      state.scale *= 1 - 0.03 * fade;
    }
  }

  return state;
};

const Tile: React.FC<{ id: TileId }> = ({ id }) => {
  const frame = useCurrentFrame();
  const s = useTileState(id, frame);
  const base = tileRects[id];
  const feature = featureByTile(id);
  const outcome = outcomes.find((o) => o.tile === id);
  const isBrand = id === "brand";
  const border = isBrand ? "transparent" : color.border;

  // Content layers scale with the tile so text and figures never reflow.
  const compactScale = s.rect.w / base.w;
  const expandedScale = Math.max(s.rect.w / WIDTH, s.rect.h / HEIGHT);
  // Layers hand off in sequence so two sets of text never overlap.
  const compactOpacity = 1 - clamp01(s.expandT / 0.3);
  const expandedOpacity = clamp01((s.expandT - 0.3) / 0.4);
  const outcomeCompact = 1 - clamp01(s.outcomeT / 0.5);
  const outcomeOpacity = clamp01((s.outcomeT - 0.5) / 0.5);
  const fig = compactFigureSize(base.w, base.h);

  return (
    <div
      style={{
        position: "absolute",
        left: s.rect.x,
        top: s.rect.y,
        width: s.rect.w,
        height: s.rect.h,
        opacity: s.opacity,
        transform: `scale(${s.scale})`,
        borderRadius: s.cornerRadius,
        background: isBrand ? color.darkBg : color.white,
        border: `1px solid ${border}`,
        boxShadow: isBrand ? "none" : shadow.figure,
        overflow: "hidden",
        zIndex: s.z,
        boxSizing: "border-box",
      }}
    >
      {isBrand ? <BrandTile /> : null}

      {feature ? (
        <>
          <div
            style={{
              position: "absolute",
              left: -1,
              top: -1,
              width: base.w,
              height: base.h,
              transform: `scale(${compactScale})`,
              transformOrigin: "top left",
              opacity: compactOpacity * outcomeCompact,
            }}
          >
            <CompactTile feature={feature} w={base.w} h={base.h}>
              <Screenshot
                screen={feature.compact.screen}
                width={fig.width}
                height={fig.height}
                zoom={feature.compact.zoom}
                focus={feature.compact.focus}
              />
            </CompactTile>
          </div>

          {outcome && outcomeOpacity > 0 ? (
            <div style={{ position: "absolute", left: -1, top: -1, width: base.w, height: base.h, opacity: outcomeOpacity }}>
              <OutcomeTile outcome={outcome} wide={base.w > 600} />
            </div>
          ) : null}

          {s.featureFrame !== null && expandedOpacity > 0 ? (
            <div
              style={{
                position: "absolute",
                left: -1,
                top: -1,
                width: WIDTH,
                height: HEIGHT,
                transform: `scale(${expandedScale})`,
                transformOrigin: "top left",
                opacity: expandedOpacity,
              }}
            >
              <Expanded feature={feature} frame={s.featureFrame} holdEnd={timing.feature - timing.featureExpand} />
            </div>
          ) : null}
        </>
      ) : null}
    </div>
  );
};

export const Bento: React.FC = () => (
  <AbsoluteFill style={{ background: color.paper }}>
    {tileOrder.map((id) => (
      <Tile key={id} id={id} />
    ))}
  </AbsoluteFill>
);
