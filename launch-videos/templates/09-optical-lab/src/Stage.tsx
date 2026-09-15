import React from "react";
import { connector, resolveLens, type PxRect } from "./geometry";
import { Media } from "./Media";
import { easeInOut, presence } from "./motion";
import type { Brand, Inspection, Layout, MediaSlot } from "./schema";

type Props = {
  slot: MediaSlot;
  stage: PxRect;
  inspection?: Inspection;
  frame: number;
  sceneDuration: number;
  brand: Brand;
  layout: Layout;
};

const OPEN_FRAMES = 12;
const CLOSE_FRAMES = 10;

/**
 * The stable field of view: the product UI flat on a bordered plate, plus (optionally)
 * one inspection window that enlarges a region of the same media, connected to its
 * origin by a hairline.
 */
export const Stage: React.FC<Props> = ({
  slot,
  stage,
  inspection,
  frame,
  sceneDuration,
  brand,
  layout,
}) => {
  const lens = inspection ? resolveLens(inspection, slot, stage) : null;
  const openAt = inspection?.openAt ?? 0;
  const closeAt = inspection?.closeAt ?? sceneDuration - CLOSE_FRAMES;
  const p = inspection ? presence(frame, openAt, closeAt, OPEN_FRAMES, CLOSE_FRAMES) : 0;
  const lineDraw = inspection ? Math.min(easeInOut(frame, openAt + 4, 14), p) : 0;
  const line = lens ? connector(lens.focus, lens.window) : null;

  return (
    <div
      style={{
        position: "absolute",
        left: stage.x,
        top: stage.y,
        width: stage.w,
        height: stage.h,
        borderRadius: layout.stageRadius,
        overflow: "hidden",
        background: brand.surface,
        boxShadow: `0 0 0 1px ${brand.line}, 0 4px 8px rgba(0,0,0,.22), 0 1px 1.5px rgba(0,0,0,.14)`,
      }}
    >
      <Media slot={slot} width={stage.w} height={stage.h} highlightColor={brand.surface} />

      {lens && line ? (
        <>
          {/* Focus region outline on the source */}
          <div
            style={{
              position: "absolute",
              left: lens.focus.x - 4,
              top: lens.focus.y - 4,
              width: lens.focus.w + 8,
              height: lens.focus.h + 8,
              borderRadius: 4,
              boxShadow: `0 0 0 1.5px ${brand.accent}`,
              opacity: p,
            }}
          />

          {/* Hairline from the focus edge to the window edge */}
          <svg
            width={stage.w}
            height={stage.h}
            style={{ position: "absolute", left: 0, top: 0, opacity: p }}
          >
            <line
              x1={line.from.x}
              y1={line.from.y}
              x2={line.to.x}
              y2={line.to.y}
              stroke={brand.accent}
              strokeWidth={1}
              strokeDasharray={line.length}
              strokeDashoffset={line.length * (1 - lineDraw)}
            />
            <circle cx={line.from.x} cy={line.from.y} r={2.5} fill={brand.accent} />
          </svg>

          {/* Inspection window */}
          <div
            style={{
              position: "absolute",
              left: lens.window.x,
              top: lens.window.y,
              width: lens.window.w,
              height: lens.window.h,
              borderRadius: layout.windowRadius,
              overflow: "hidden",
              background: brand.white,
              boxShadow: `0 0 0 ${layout.windowBorder}px ${brand.accent}, 0 0 0 ${layout.windowBorder + 3}px ${brand.white}, 0 4px 8px rgba(0,0,0,.22), 0 1px 1.5px rgba(0,0,0,.14)`,
              opacity: p,
              transform: `scale(${0.96 + 0.04 * p})`,
              transformOrigin: `${line.to.x - lens.window.x}px ${line.to.y - lens.window.y}px`,
            }}
          >
            <Media
              slot={slot}
              width={stage.w}
              height={stage.h}
              zoom={lens.zoom}
              offsetX={-lens.focus.x * lens.zoom}
              offsetY={-lens.focus.y * lens.zoom}
              highlightColor={brand.surface}
            />
          </div>
        </>
      ) : null}
    </div>
  );
};
